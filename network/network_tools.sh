#! /usr/bin/env bash

if [[ $(id -u) -ne 0 ]]; then
  echo "Running as root"
  sudo "$0" "$@"
  exit $?
fi


reload_modules() {
  echo "Reloading modules"
  rmmod iwlmvm iwlwifi
  modprobe iwlwifi
  systemctl restart NetworkManager
  until via_gateway "$1" > /dev/null; do
    printf "."
    sleep 1
  done
  echo
}

via_gateway() {
  local gateway="$(ip route \
    | grep -P "\S+ via [0-9.]+ dev $1 proto .*" \
    | head -1 \
    | awk {'print $3'})"
  [ ! -z "$gateway" ] && echo "via $gateway"
}

set_routes() {
  local iface=$1; shift
  for subnet in $@; do
    ip route del $subnet 2>/dev/null
    ip route add $subnet dev $iface $(via_gateway $iface)
  done
  echo "Set routes ($iface)"
}

set_dns_servers() {
  echo "# Generated by network_tools.sh" > /etc/resolv.conf
  for ip in $@; do
    echo "nameserver $ip" >> /etc/resolv.conf
  done
  echo "Set DNS servers (${@})"
}

set_default_interface() {
  local iface=$1
  while read -r route; do
    echo "Deleted: $route"
    ip route del $route
  done < <(ip r | grep -P "^default" | grep -v "metric")
  ip route add default dev $iface $(via_gateway $iface)
  echo "Set default interface ($iface)"
}

"$@"