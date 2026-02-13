#!/bin/sh

# 1. Directory Setup
ROOTFS_DIR=$(pwd)/ubuntu-fs
ARCH=$(uname -m)

echo "--- SYSTEM CHECK ---"
echo "Current Directory: $(pwd)"
echo "Available Space:"
df -h . | awk 'NR==2 {print "Total: "$2", Used: "$3", Free: "$4}'
echo "--------------------"

# 2. Architecture Detection
if [ "$ARCH" = "x86_64" ]; then ARCH_ALT=amd64; 
elif [ "$ARCH" = "aarch64" ]; then ARCH_ALT=arm64; 
else echo "Unsupported ARCH"; exit 1; fi

# 3. Installation
mkdir -p "$ROOTFS_DIR"

echo "[1/3] Downloading Ubuntu RootFS..."
ROOTFS_FILE="ubuntu-rootfs.tar.gz"
wget --no-check-certificate -O "$ROOTFS_FILE" "http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-${ARCH_ALT}.tar.gz"

if [ ! -s "$ROOTFS_FILE" ] || [ $(stat -c%s "$ROOTFS_FILE") -lt 1000000 ]; then
    echo "ERROR: Download fail ho gaya ya file bahut choti hai."
    ls -lh "$ROOTFS_FILE"
    exit 1
fi

echo "[2/3] Extracting (Dhyan se dekhein agar koi error aata hai)..."
# -v flag lagaya hai taki har file dikhe
tar -xzvf "$ROOTFS_FILE" -C "$ROOTFS_DIR" 2>&1 | tail -n 10

if [ ! -f "$ROOTFS_DIR/bin/bash" ] && [ ! -f "$ROOTFS_DIR/usr/bin/bash" ]; then
    echo ""
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "EXTRACTION FAILED!"
    echo "Files /bin/bash nahi mili."
    echo "Shayad aapka Disk Space full ho gaya hai."
    echo "Upar ki lines mein 'No space left on device' check karein."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
fi

rm "$ROOTFS_FILE"

echo "[3/3] Setting up PRoot..."
mkdir -p "$ROOTFS_DIR/usr/local/bin"
PROOT_BIN="$ROOTFS_DIR/usr/local/bin/proot"
wget --no-check-certificate -O "$PROOT_BIN" "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"
chmod 755 "$PROOT_BIN"

# DNS Setup
mkdir -p "$ROOTFS_DIR/etc"
echo "nameserver 1.1.1.1" > "$ROOTFS_DIR/etc/resolv.conf"

touch "$ROOTFS_DIR/.installed"

echo "Installation Successful!"

# 4. Launch
if [ -f "$ROOTFS_DIR/usr/bin/bash" ] && [ ! -f "$ROOTFS_DIR/bin/bash" ]; then
    ln -s /usr/bin/bash "$ROOTFS_DIR/bin/bash"
fi

"$PROOT_BIN" \
  --rootfs="${ROOTFS_DIR}" \
  --link2symlink \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc -b /etc/resolv.conf \
  --kill-on-exit \
  /bin/bash
