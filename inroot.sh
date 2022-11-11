#!/bin/bash -e

# Script to be run in the target root to setup some basic stuffs

basic_setup() {
  echo " => Basic setup inside the target root"
  echo "  -> Setting timezone to Asia/Shanghai"
  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
  echo "  -> Enabling locales en_US.UTF-8, en_GB.UTF-8, zh_CN.UTF-8"
  local locale_zh='zh_CN.UTF-8 UTF-8'
  local locale_gb='en_GB.UTF-8 UTF-8'
  local locale_us='en_US.UTF-8 UTF-8'
  sed -i "
    s|^#${locale_zh}  $|${locale_zh}  |g
    s|^#${locale_gb}  $|${locale_gb}  |g
    s|^#${locale_us}  $|${locale_us}  |g
  " '/etc/locale.gen'
  echo "  -> Generating locales..."
  locale-gen
  echo "  -> Setting en_GB.UTF-8 as locale"
  echo 'LANG=en_GB.UTF-8' > /etc/locale.conf
  echo "  -> Setting hostname to alarm"
  echo 'alarm' > /etc/hostname
  echo "  -> Setting basic localhost"
  printf '127.0.0.1\tlocalhost\n::1\t\tlocalhost\n' >> /etc/hosts
  echo "  -> Setting DHCP on eth* with systemd-networkd"
  printf '[Match]\nName=eth*\n\n[Network]\nDHCP=yes\nDNSSEC=no\n' > /etc/systemd/network/20-wired.network 
  echo "  -> Enabling systemd-networkd and systemd-resolved"
  systemctl enable systemd-networkd.service systemd-resolved.service
}

install_pkgs() {
  echo " => Installing more essential packages..."
  echo "  -> openssh: for remote management"
  echo "  -> vim: for text editting"
  echo "  -> sudo: for permission management"
  pacman -Syu openssh vim sudo
  echo " => Essential packages installed"
}

vim_as_vi() {
  echo " => Setting VIM as VI..."
  ln -sf 'vim' '/usr/bin/vi'
  echo " => Set VIM as VI"
}

setup_sudo() {
  echo " => Setting up sudo, to allow users in group wheel to use sudo with password"
  local sudoers='/etc/sudoers'
  chmod o+w "${sudoers}"
  sed -i 's|^# %wheel ALL=(ALL:ALL) ALL$|%wheel ALL=(ALL:ALL) ALL|g' "${sudoers}"
  chmod o-w "${sudoers}"
  echo " => sudo set up"
}

setup_users() {
  echo " => Setting up users, root and a newly created user in the wheel group will be set with a temporary password"
  local key='please_change_me'
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

setup_ssh() {
  echo " => Setting up SSH"
  echo '  -> Allowing to login as root with password'
  sed 's|^#PermitRootLogin prohibit-password$|PermitRootLogin yes|g' 'etc/ssh/sshd_config'
  echo '  -> Enabling sshd.service'
  systemctl enable sshd.service
  echo " => SSH set up"
}

pkg_clean() {
  echo " => Cleaning Pacman package cache..."
  rm -rf /var/cache/pacman/pkg/*
  echo " => Pacman cache cleaned"
}

inside_root() {
  basic_setup
  install_pkgs
  vim_as_vi
  setup_sudo
  setup_users
  setup_ssh
  pkg_clean
}

inside_root