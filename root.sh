
#!/bin/sh

# 1. Basic Settings
ROOTFS_DIR=$(pwd)/ubuntu-fs
ARCH=$(uname -m)
max_retries=5
timeout=30

# 2. Architecture Check
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  echo "Unsupported CPU architecture: ${ARCH}"
  exit 1
fi

# 3. Installation Process
if [ ! -d "$ROOTFS_DIR" ] || [ ! -f "$ROOTFS_DIR/.installed" ]; then
  echo "###########################################"
  echo "#      Ubuntu 22.04 Installer Started     #"
  echo "###########################################"

  # Clean folder if exists
  rm -rf "$ROOTFS_DIR"
  mkdir -p "$ROOTFS_DIR"

  echo "[1/4] Downloading Ubuntu 22.04 RootFS..."
  ROOTFS_FILE="ubuntu-rootfs.tar.gz"
  wget --tries=$max_retries --timeout=$timeout --no-check-certificate -O "$ROOTFS_FILE" \
    "http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-${ARCH_ALT}.tar.gz"

  if [ ! -s "$ROOTFS_FILE" ]; then
    echo "ERROR: Download fail ho gaya. Check your internet connection."
    exit 1
  fi

  echo "[2/4] Extracting RootFS (Isme thoda waqt lagega)..."
  # -z for gzip, -x for extract
  tar -xzf "$ROOTFS_FILE" -C "$ROOTFS_DIR" || {
    echo "ERROR: Extraction fail ho gayi! Disk space check karein."
    exit 1
  }

  # Download file delete karein
  rm "$ROOTFS_FILE"

  echo "[3/4] Setting up system files..."
  # Zaroori folders manually check karein
  mkdir -p "$ROOTFS_DIR/etc"
  mkdir -p "$ROOTFS_DIR/root"
  mkdir -p "$ROOTFS_DIR/tmp"
  mkdir -p "$ROOTFS_DIR/usr/local/bin"
  
  # DNS set karein
  printf "nameserver 1.1.1.1\nnameserver 8.8.8.8" > "$ROOTFS_DIR/etc/resolv.conf"

  # 4. Setup PRoot
  echo "[4/4] Downloading PRoot binary..."
  PROOT_BIN="$ROOTFS_DIR/usr/local/bin/proot"
  wget --no-check-certificate -O "$PROOT_BIN" "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"
  
  if [ -s "$PROOT_BIN" ]; then
    chmod 755 "$PROOT_BIN"
  else
    echo "ERROR: PRoot download fail ho gaya."
    exit 1
  fi

  touch "$ROOTFS_DIR/.installed"
  echo "Installation Complete!"
fi

# 5. Bash Verification
# Ubuntu Base me kabhi kabhi bash /bin me nahi sirf /usr/bin me hota hai
if [ ! -f "$ROOTFS_DIR/bin/bash" ]; then
    if [ -f "$ROOTFS_DIR/usr/bin/bash" ]; then
        ln -s /usr/bin/bash "$ROOTFS_DIR/bin/bash"
    else
        echo "FATAL ERROR: Ubuntu files sahi se extract nahi hui."
        echo "Suggestion: Disk space check karein aur 'rm -rf ubuntu-fs' karke dobara chalayein."
        exit 1
    fi
fi

# 6. Launching Ubuntu
clear
echo -e "\033[0;36m"
echo "___________________________________________________"
echo ""
echo "           -----> Ubuntu 22.04 Started ! <----"
echo "___________________________________________________"
echo -e "\033[0m"

# Execute using PRoot
"$ROOTFS_DIR/usr/local/bin/proot" \
  --rootfs="${ROOTFS_DIR}" \
  --link2symlink \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc -b /etc/resolv.conf \
  --kill-on-exit \
  /usr/bin/env -i \
  HOME=/root \
  TERM="$TERM" \
  PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin \
  /bin/bash --login
