#! /usr/bin/env bash

if [[ $(id -u) -ne 0 ]]; then
  echo "Running as root"
  sudo "$0" "$@"
  exit $?
fi


cmd_dir="${BASH_SOURCE%/*}"
. "${cmd_dir}/config"

network_tools() { "${cmd_dir}/network_tools.sh" "$@"; }
routes()        { "${cmd_dir}/routes.sh" "$@"; }

retries=5

wifi=wlp3s0
cable=enp0s25


_log() {
  echo "$(date +"%F %T") -- $@"
}

# Test ping with single IP or domain name
# Usage:  test_connection 1.2.3.4
#         test_connection a.org
test_connection() {
  local i=0
  until timeout 1 ping -q $1 -w 1 -c 1 &>/dev/null; do
    (( $((++i)) > $retries )) && return 1
    _log "Failed ($1), Retry $i/$retries"
    sleep 1
  done
}

# Test ping with list of IPs or domain names
# Usage:  test_connection 1.2.3.4 5.6.7.8
#         test_connection a.org b.org
hash fping && test_connection() {
  local i=0
  until test -n "$(timeout 1 head -n 1 <(fping $@ -aqr 5))"; do
    (( $((++i)) > $retries )) && return 1
    _log "Failed ($@), Retry $i/$retries"
    sleep 1
  done
}

reset_connection() {
  _log "Restarting $active_connection"
  routes $active_connection
}

try_cable() {
  local previous=$active_connection
  network_tools via_gateway $cable > /dev/null \
    && active_connection=cable \
    || active_connection=vpn
  [ "$active_connection" = "$previous" ] || reset_connection
}

while :; do
  try_cable
  if ! test_connection 1.1.1.1; then
    network_tools reload_modules $wifi
    network_tools set_default_interface $wifi
    network_tools set_dns_servers ${DNS_SERVERS[@]}
  elif ! test_connection ${DNS_SERVERS[@]}; then
    reset_connection
  elif ! host "$CONNECTION_TEST" > /dev/null; then
    network_tools set_dns_servers ${DNS_SERVERS[@]}
  else
    _log "Still alive! ($active_connection)"
    sleep 10
  fi
done
