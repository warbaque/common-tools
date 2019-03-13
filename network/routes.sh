#! /usr/bin/env bash

if [[ $(id -u) -ne 0 ]]; then
  echo "Running as root"
  sudo "$0" "$@"
  exit $?
fi


cmd_dir="${BASH_SOURCE%/*}"
. "${cmd_dir}/config"

network_tools() {
  "${cmd_dir}/network_tools.sh" "$@"
}


_rsa_securid_code() {
  stoken tokencode -p $TOKEN_PASSWORD -n $TOKEN_PIN
}

_rsa_securid_codes() {
  generator_pipe="$(mktemp -u -t generator-pipe-XXX)"
  mkfifo "$generator_pipe"
  while :; do
    local prev="$code"
    local code="$(_rsa_securid_code)"
    [ "$prev" = "$code" ] || echo "$code"
    sleep 1
  done > "$generator_pipe" &
  generator_pid=$!
  trap 'rm -f "$generator_pipe"; kill "$generator_pid"' EXIT
}

_routes() {
  network_tools set_default_interface wlp3s0
  network_tools set_routes $1 ${ROUTES[@]}
  network_tools set_dns_servers ${DNS_SERVERS[@]}
}

cable() {
  _routes enp0s25
}

vpn() {
  network_tools set_dns_servers 8.8.8.8 8.8.4.4

  _rsa_securid_codes
  vpnc-disconnect
  vpnc-connect "${VPN_CONFIG:-default}" < "$generator_pipe" ||
    { echo "Starting VPNC failed"; exit 1; }
  _routes tun0
}

"$@"
