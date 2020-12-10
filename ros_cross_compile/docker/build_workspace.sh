#!/bin/bash
set -euxo pipefail

cleanup() {
  chown -R "${OWNER_USER}" .
}

trap 'cleanup' EXIT

mkdir -p /opt/ros/"${ROS_DISTRO}"
touch /opt/ros/"${ROS_DISTRO}"/setup.bash

set +ux
# shellcheck source=/dev/null
source /opt/ros/"${ROS_DISTRO}"/setup.bash
set -ux
colcon build --mixin "${TARGET_ARCH}"-docker \
  --build-base build_"${TARGET_ARCH}" \
  --install-base install_"${TARGET_ARCH}"
