#!/bin/bash
set -euxo pipefail

if [ ! -d ./src ]; then
  echo "No src/ directory found at $(pwd), did you remember to mount your workspace?"
  exit 1
fi

if [ -f "${CUSTOM_SETUP}" ]; then
  chmod +x "${CUSTOM_SETUP}"
  pushd "$(dirname "${CUSTOM_SETUP}")"
  "${CUSTOM_SETUP}"
  popd
fi

out_dir=$(dirname "${OUT_PATH}")
mkdir -p "${out_dir}"

rosdep update

cat > "${OUT_PATH}" <<EOF
#!/bin/bash
set -euxo pipefail
EOF

mapfile -t package_paths < <(colcon list -p)

rosdep install \
    --os "${TARGET_OS}" \
    --rosdistro "${ROSDISTRO}" \
    --from-paths "${package_paths[@]}" \
    --ignore-src \
    --reinstall \
    --default-yes \
    --skip-keys "${SKIP_ROSDEP_KEYS}" \
    --simulate \
  >> /tmp/all-deps.sh

# Find the non-apt lines and move them as-is to the final script
grep -v "apt-get install -y" /tmp/all-deps.sh >> "${OUT_PATH}" || true

# Find all apt-get lines from the rosdep output
# As an optimization, we will combine all such commands into a single command to save time
grep "apt-get install -y" /tmp/all-deps.sh > /tmp/apt-deps.sh || true
# awk notes:
#  "apt-get", "install", "-y", package_name is the fourth column
#  OSR=' ' makes the output space-separated instead of newline-separated output
echo "apt-get install -y $(awk '{print $4}' OSR=' ' < /tmp/apt-deps.sh)" >> "${OUT_PATH}"

chmod +x "${OUT_PATH}"
chown -R "${OWNER_USER}" "${out_dir}"
