/*
   This file is part of zsrelay a srelay port for the iPhone.

   Copyright (C) 2008 Rene Koecher <shirk@bitspin.org>

   Based on srelay 0.4.6 source base Copyright (C) 2001 Tomo.M
   Destributed under the GPL license with original authors permission.

   zsrelay is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or (at
   your option) any later version.

   This program is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>. 
*/

#include <syslog.h>
#include <stdarg.h>
#include <fcntl.h>
#include <sys/wait.h>
#include "zsrelay.h"

#ifdef LOCAL_FAC
# define LOCALFAC  LOCAL_FAC
#else
# define LOCALFAC  0
#endif
#ifdef SYSLOG_FAC
#  define SYSLOGFAC (SYSLOG_FAC|LOCALFAC)
#else
#  define SYSLOGFAC (LOG_DAEMON|LOCALFAC)
#endif

int forcesyslog = 0;

void msg_out(int severity, const char *fmt, ...)
{
  va_list ap;
  int priority;

  switch (severity) {
  case crit:
    priority = SYSLOGFAC|LOG_ERR;
    break;
  case warn:
    priority = SYSLOGFAC|LOG_WARNING;
    break;
  case norm:
  default:
    priority = SYSLOGFAC|LOG_INFO;
    break;
  }

  va_start(ap, fmt);
  if (!forcesyslog && isatty(fileno(stderr))) {
    vfprintf(stderr, fmt, ap);
  } else {
    vsyslog(priority, fmt, ap);
  }
  va_end(ap);
}

/*
  set_blocking:
          i/o mode to descriptor
 */
void set_blocking(int s)
{
  int flags;

  flags = fcntl(s, F_GETFL);
  if (flags >= 0) {
    fcntl(s, F_SETFL, flags & ~O_NONBLOCK);
  }
}

int settimer(int sec)
{
  struct itimerval it, ot;

  it.it_interval.tv_sec = 0;
  it.it_interval.tv_usec = 0;
  it.it_value.tv_sec = sec;
  it.it_value.tv_usec = 0;
  if (setitimer(ITIMER_REAL, &it, &ot) == 0) {
    return(ot.it_value.tv_sec);
  } else {
    return(-1);
  }
}

void feed_sig(char c)
{
  if (write(sig_queue[1], &c, 1) != 1) {
    msg_out(crit, "write: %m");
    exit(-1);
  }
}

/**  SIGALRM handling **/
void timeout(int signo)
{
  return;
}

void do_sigchld(int signo)
{
  feed_sig('C');
}

void do_sighup(int signo)
{
  feed_sig('H');
}

void do_sigterm(int signo)
{
  feed_sig('T');
}

void reapchild()
{
  int olderrno = errno;
  pid_t pid;
  int status, count;

  count=0;
  while ((pid = waitpid(-1, &status, WNOHANG)) > 0) {
    proclist_drop(pid);
    if (count++ > 1000) {
      /* reapchild: waitpid loop */
      break;
    }
  }
  errno = olderrno;
}

void cleanup()
{
  /* unlink PID file */
  if (pidfile != NULL) {
    setreuid(PROCUID, 0);
    unlink(pidfile);
    setreuid(0, PROCUID);
  }
  msg_out(norm, "sig TERM received. exitting...");
  exit(0);
}

void reload()
{
  FILE *fp;

#ifdef USE_THREAD
  if (threading) {
    if (! pthread_equal(pthread_self(), main_thread)) {
      /* do nothing */
      return;
    }
  }
#endif
  msg_out(norm, "reloading initiated ...");
  if ((fp = fopen(config, "r")) != NULL) {
    if (readconf(fp) != 0)
      msg_out(warn, "reloading failed.");
    fclose(fp);
  }
  msg_out(norm, "reloading done.");
}

sigfunc_t setsignal(int sig, sigfunc_t handler)
{
  struct sigaction n, o;

  memset(&n, 0, sizeof n);
  n.sa_handler = handler;

  if (sig != SIGALRM) {
    n.sa_flags = SA_RESTART;
  }

  if (sigaction(sig, &n, &o) < 0)
    return SIG_ERR;
  return o.sa_handler;
}

int blocksignal(int sig)
{
  sigset_t sset, oset;

  sigemptyset(&sset);
  sigaddset(&sset, sig);
  if (sigprocmask(SIG_BLOCK, &sset, &oset) < 0)
    return -1;
  else
    return sigismember(&oset, sig);
}

int releasesignal(int sig)
{
  sigset_t sset, oset;

  sigemptyset(&sset);
  sigaddset(&sset, sig);
  if (sigprocmask(SIG_UNBLOCK, &sset, &oset) < 0)
    return -1;
  else
    return sigismember(&oset, sig);
}

static pid_t    *proclist = NULL;
static int      proclist_size = 0;
#define PROCLIST_SEG      32

void proclist_add(pid_t pid)
{
  int i;
  void proclist_probe(void);

  for (i = 0; i < proclist_size; i++) {
    if (proclist[i] == (pid_t)0)
      break;
  }
  if (i >= proclist_size) {
    proclist_probe();
    for (i = 0; i < proclist_size; i++) {
      if (proclist[i] == 0)
	break;
    }
  }
  if (i >= proclist_size) {
    pid_t *new_proclist;

    new_proclist = (pid_t *)malloc(sizeof(pid_t)
				   * (proclist_size + PROCLIST_SEG));
    if (new_proclist == (pid_t *)NULL) {
      msg_out(warn, "could not malloc proclist");
      /* XXX */
      return;
    }
    if (proclist_size > 0) {
      memcpy(proclist, new_proclist, proclist_size * sizeof(pid_t));
      free(proclist);
    }
    for (i = proclist_size; i < proclist_size + PROCLIST_SEG; i++) {
      new_proclist[i] = 0;
    }
    i = proclist_size;
    proclist_size += PROCLIST_SEG;
    proclist = new_proclist;
  }
  proclist[i] = pid;
  cur_child++;
}

void proclist_drop(pid_t pid)
{
  int i;

  for (i = 0; i < proclist_size; i++) {
    if (proclist[i] == pid) {
      proclist[i] = 0;
      break;
    }
  }
  if (cur_child > 0)
    cur_child--;
}

void proclist_probe()
{
  int i;

  for (i = 0; i < proclist_size; i++) {
    if (proclist[i] == 0)
      continue;
    if (kill(proclist[i], 0) < 0) {
      /* lost child pid */
      proclist[i] = 0;
      cur_child--;
    }
  }
  if (cur_child < 0)
    cur_child = 0;
}
