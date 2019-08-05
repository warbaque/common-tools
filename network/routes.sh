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

_vpnc() {
  _rsa_securid_codes
  vpnc-disconnect
  vpnc-connect "${VPNC_CONFIG_FILE:-default}" < "$generator_pipe" ||
    { echo "Starting vpnc failed"; exit 1; }
}

_openvpn() {
  pkill openvpn
  openvpn \
      --cd "$OPENVPN_CONFIG_DIR" \
      --config "$OPENVPN_CONFIG_FILE" --daemon ||
    { echo "Starting openvpn failed"; exit 1; }
}

cable() {
  _routes enp0s25
}

vpn() {
  network_tools set_dns_servers 8.8.8.8 8.8.4.4

  if  test -n "$OPENVPN_CONFIG_DIR" &&
      test -n "$OPENVPN_CONFIG_FILE"; then
    _openvpn
  elif  test -n "$VPNC_CONFIG" &&
        test -n "$TOKEN_PASSWORD" &&
        test -n "$TOKEN_PIN"; then
    _vpnc
  fi

  _routes tun0
}

"$@"
