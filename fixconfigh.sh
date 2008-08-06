#!/bin/bash
find . -name 'config.h' -exec sed -i -e 's/#define LINUX/#define FREEBSD/g' '{}' ';'
