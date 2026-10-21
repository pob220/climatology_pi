#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y --no-install-recommends build-essential cmake gettext git ca-certificates lsb-release libgtk-3-dev libgl1-mesa-dev libglu1-mesa-dev libbz2-dev zlib1g-dev python3 libxml2-utils
if [[ "$VERSION_ID" == 11 ]]; then
  apt-get install -y libwxgtk3.0-gtk3-dev libwxgtk3.0-gtk3-0v5
elif [[ "$VERSION_ID" == 22.04 ]]; then
  apt-get install -y software-properties-common
  add-apt-repository -y ppa:opencpn/opencpn
  apt-get update -qq
  apt-get install -y libwxgtk3.2-dev
else
  apt-get install -y libwxgtk3.2-dev
fi
cmake -S . -B build-public -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build build-public --parallel 3
ctest --test-dir build-public --output-on-failure
python3 ci/public-packages/package.py --binary build-public/libclimatology_pi.so --build-dir build-public --kind linux --target "$PACKAGE_TARGET" --target-version "$VERSION_ID" --arch "$PACKAGE_ARCH"
for xml in public-packages/*.xml; do xmllint --noout --schema ci/public-packages/ocpn-plugin.xsd "$xml"; done
