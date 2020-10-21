#! /usr/bin/env bash

dyfi_env="${BASH_SOURCE[0]%/*}/dyfi.env"
test -f "${dyfi_env}" && . "${dyfi_env}"

update_hostname_mappings() {
  local dyfi_api="https://www.dy.fi/nic/update?hostname="
  local hostname="${1}"
  local credentials="${2}:${3}"
  curl -sD - --user "${credentials}" "${dyfi_api}${hostname}"
}

hostname="${1}"
username="${2:-${DYFI_USERNAME}}"
password="${3:-${DYFI_PASSWORD}}"

test -z "${hostname}" && { echo "dy.fi hostname missing!"; exit 1; }
test -z "${username}" && { echo "dy.fi username missing!"; exit 1; }
test -z "${password}" && { echo "dy.fi password missing!"; exit 1; }

hostip="$(getent hosts "${hostname}" | awk '{ print $1 }')"
myip="$(ip route get to 1.1.1.1 | sed -nr 's/.*src ([0-9.]+) .*/\1/p')"

# if ip is local get public
echo "${myip}" | grep -P '^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|31)\.)' >/dev/null &&
  myip="$(curl -s ip4.icanhazip.com)"

tmpfile="/tmp/dyfi-${hostname}"
tmp_age="$(date -d "now - $(stat -c %Y "${tmpfile}" 2>/dev/null) seconds" +%s)"

# remove tmp if it isn't in sync after 3 minutes since last update
(( "${tmp_age}" > 60*3 )) && [ "$(cat "${tmpfile}")" != "${hostip}" ] &&
  { echo "tmp isn't in sync, removing"; rm "${tmpfile}"; }

# last update < 5 days ago
(( "${tmp_age}" < 24*60*60*5 )) && [ "$(cat "${tmpfile}")" = "${myip}" ] &&
  { echo "tmp ok (age: ${tmp_age} seconds), no change"; exit; }

update_hostname_mappings "${hostname}" "${username}" "${password}"
echo -en "${myip}" > "${tmpfile}"
