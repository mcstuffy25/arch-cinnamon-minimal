#!/bin/zsh

echo "Manually installed packages:"
comm -23 <(apt-mark showmanual | sort) <(gzip -dc /var/log/installer/initial-status.gz | awk '{print $2}' | sort)
