#!/usr/bin/env bash
# Checks that every HTTPS host the firmware talks to still chains to a root in
# the pinned CA bundle (packages/certs/ca_bundle.pem), and that no root in the
# bundle expires soon. The devices trust ONLY this bundle, so a host moving to
# a CA that is not in it would silently stop cloud uploads and OTA update
# checks. Run in CI (.github/workflows/ca-bundle.yml) and before each release.
#
# Usage: scripts/check_ca_bundle.sh [bundle] [min_days_valid]
set -euo pipefail

bundle="${1:-packages/certs/ca_bundle.pem}"
min_days="${2:-365}"
hosts=(hw.airgradient.com luukvisser.github.io)
failed=0

# 1. Every host's served chain verifies against the bundle alone, including
#    the hostname check (OpenSSL falls back to the subject CN when there is no
#    subjectAltName, as mbedTLS on the device does).
# Try twice so a transient network error does not fail the weekly run.
check_host() {
  timeout 20 openssl s_client -connect "${1}:443" -servername "${1}" \
    -CAfile "${bundle}" -no-CApath -no-CAstore -verify_hostname "${1}" \
    -verify_return_error </dev/null 2>&1 || true
}
for host in "${hosts[@]}"; do
  out=$(check_host "${host}")
  if ! grep -q "Verify return code:" <<<"${out}"; then
    sleep 10
    out=$(check_host "${host}")
  fi
  if grep -q "Verify return code: 0 (ok)" <<<"${out}"; then
    root=$(grep -E "^ *[0-9]+ s:" <<<"${out}" | tail -n1 | sed 's/^ *[0-9]* s://' || true)
    echo "OK    ${host}  (chain top: ${root:-unknown})"
  elif grep -q "Verify return code:" <<<"${out}"; then
    # The TLS handshake happened, so this is a real certificate problem.
    echo "::error::${host} does not verify against ${bundle}"
    grep -E "verify error|Verify return code|^ *[0-9]+ [si]:" <<<"${out}" || true
    failed=1
  else
    # No handshake (DNS, timeout, connection refused): not a bundle problem.
    echo "::error::Could not connect to ${host}:443 to check its certificate (network error, not a bundle problem)"
    tail -n 5 <<<"${out}" || true
    failed=1
  fi
done

# 2. No root in the bundle expires within min_days.
tmp=$(mktemp -d)
trap 'rm -rf "${tmp}"' EXIT
awk -v dir="${tmp}" '/BEGIN CERTIFICATE/{n++; f=sprintf("%s/%02d.pem", dir, n)} f{print > f} /END CERTIFICATE/{f=""}' "${bundle}"
for cert in "${tmp}"/*.pem; do
  subject=$(openssl x509 -in "${cert}" -noout -subject -nameopt sep_multiline | sed -n 's/^ *CN=//p')
  if openssl x509 -in "${cert}" -noout -checkend $((min_days * 86400)) >/dev/null; then
    echo "OK    root '${subject}' valid for at least ${min_days} more days"
  else
    echo "::error::root '${subject}' expires within ${min_days} days: $(openssl x509 -in "${cert}" -noout -enddate)"
    failed=1
  fi
done

exit "${failed}"
