#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
mkdir -p /etc/ssl/certs
cp /tmp/build-ca.crt /etc/ssl/certs/ca-certificates.crt
# Verify HTTPS with the runner certificate bundle explicitly.
cat > /etc/apt/apt.conf.d/99-public-build <<'EOF'
Acquire::https::CaInfo "/tmp/build-ca.crt";
Acquire::Retries "3";
Acquire::http::No-Cache "true";
EOF
# Use HTTPS to avoid stale intermediary package indexes.
sed -i "s|http://deb.debian.org|https://deb.debian.org|g; s|http://security.debian.org|https://security.debian.org|g" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null || true
# A fresh mirror URL avoids obsolete security indexes served by intermediaries.
sed -i 's|https://deb.debian.org/debian-security|https://security.debian.org/debian-security|g; s|https://deb.debian.org/debian|https://ftp.debian.org/debian|g' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null || true
apt-get update -qq --error-on=any
apt-get install -y --no-install-recommends build-essential cmake gettext git ca-certificates lsb-release libgtk-3-dev libgl1-mesa-dev libglu1-mesa-dev libbz2-dev zlib1g-dev python3 libxml2-utils
git config --global --add safe.directory /source
if [[ "$VERSION_ID" == 11 ]]; then
  apt-get install -y libwxgtk3.0-gtk3-dev libwxgtk3.0-gtk3-0v5
elif [[ "$VERSION_ID" == 22.04 ]]; then
  apt-get install -y software-properties-common
  add-apt-repository -y ppa:opencpn/opencpn
  apt-get update -qq
  apt-get -o Acquire::Retries=5 install -y libwxgtk3.2-dev
else
  apt-get -o Acquire::Retries=5 install -y libwxgtk3.2-dev
fi
cmake -S . -B build-public -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build-public --parallel 3
ctest --test-dir build-public --output-on-failure
python3 ci/public-packages/package.py --binary build-public/libclimatology_pi.so --build-dir build-public --kind linux --target "$PACKAGE_TARGET" --target-version "$VERSION_ID" --arch "$PACKAGE_ARCH"
for xml in public-packages/*.xml; do xmllint --noout --schema ci/public-packages/ocpn-plugin.xsd "$xml"; done
