#!/usr/bin/env bash

[ -n "$PS1" ]

# According to the bash man page, .bash_profile is executed for login shells,
# while .bashrc is executed for interactive non-login shells.
source ~/.bash_profile
