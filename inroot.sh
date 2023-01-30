#!/bin/bash -e

# Script to be run in the target root to setup some basic stuffs

basic_setup() {
  echo " => Basic setup inside the target root"
  echo "  -> Generating locales..."
  locale-gen
  echo "  -> Enabling systemd-networkd, systemd-resolved and systemd"
  systemctl enable systemd-networkd.service systemd-resolved.service sshd.service
}

setup_users() {
  echo " => Setting up users, root and a newly created user in the wheel group will be set with a temporary password"
  local key='alarm_please_change_me'
  echo "  -> Temporary password is ${key}"
  local user='alarm'
  echo "  -> Creating user ${user}"
  useradd -g wheel -m "${user}"
  echo "  -> Setting root's password to ${key}"
  printf '%s\n%s\n' "${key}" "${key}" | passwd
  echo "  -> Setting ${user}'s password to ${key}"
  printf '%s\n%s\n' "${key}" "${key}" | passwd alarm
  echo " => Users set up"
}

inside_root() {
  basic_setup
  setup_users
}

inside_root
