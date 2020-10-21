#! /usr/bin/env bash

common_tools="$(cd "${BASH_SOURCE[0]%/*}/../.." && pwd -P)"


example() {
  cat << EOF > "${common_tools}/configs/vpn/vpn.env"
VPN_ENDPOINT=wg0.example.com
VPN_SSH_KEY_PUBLIC="${configs}/vpn/algo/vpn.pub"
VPN_CA_PASSWORD=password
EOF

  cat << EOF > "${common_tools}/configs/vpn/dyfi.env"
DYFI_USERNAME=username
DYFI_PASSWORD=password
EOF

  ssh-keygen -o -a 100 -t ed25519 -N "" -f "${common_tools}/configs/vpn/algo/vpn" <<< y
  mv "${common_tools}/configs/vpn/algo/vpn"{,.pem}

  cp "${common_tools}/configs/vpn/algo/config.cfg"{.example,}
}


from-secrets() {
  cp "${common_tools}/"{secrets,configs}"/vpn/vpn.env"
  cp "${common_tools}/"{secrets,configs}"/vpn/algo/vpn.pub"
  cp "${common_tools}/"{secrets,configs}"/vpn/algo/vpn.pem"
  cp "${common_tools}/"{secrets,configs}"/vpn/algo/config.cfg"
  cp "${common_tools}/"{secrets,configs/vpn}"/dyfi.env"
  chmod 600 "${common_tools}/configs/vpn/algo/vpn.pem"
}

"${@}"
