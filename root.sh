#!/bin/sh

# 1. Setup
ROOTFS_DIR=$(pwd)/ubuntu-fs
ARCH=$(uname -m)

# Purana 0-byte file delete karein
rm -f ubuntu-rootfs.tar.gz

# 2. Architecture Detection
if [ "$ARCH" = "x86_64" ]; then
    ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    ARCH_ALT=arm64
else
    echo "Unsupported ARCH: $ARCH"
    exit 1
fi

# 3. Installation
if [ ! -d "$ROOTFS_DIR/.installed" ]; then
    mkdir -p "$ROOTFS_DIR"
    
    echo "--- Step 1: Downloading Ubuntu 22.04 (HTTPS use kar rahe hain) ---"
    
    # URL ko HTTP se HTTPS mein badal diya hai
    URL="https://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-${ARCH_ALT}.tar.gz"
    
    wget --no-check-certificate -O ubuntu-rootfs.tar.gz "$URL"

    # Agar pehla link fail ho toh doosra mirror (Alternative Mirror)
    if [ ! -s ubuntu-rootfs.tar.gz ]; then
        echo "Pehla link fail hua, doosre server se koshish kar rahe hain..."
        URL_ALT="https://mirrors.edge.kernel.org/ubuntu-cdimage/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-${ARCH_ALT}.tar.gz"
        wget --no-check-certificate -O ubuntu-rootfs.tar.gz "$URL_ALT"
    fi

    if [ ! -s ubuntu-rootfs.tar.gz ]; then
        echo "ERROR: Download dono servers se fail ho gaya. Shayad aapka firewall port 443 block kar raha hai."
        exit 1
    fi

    echo "--- Step 2: Extracting RootFS ---"
    tar -xzf ubuntu-rootfs.tar.gz -C "$ROOTFS_DIR" || { echo "Extraction fail!"; exit 1; }
    rm ubuntu-rootfs.tar.gz

    # Setup essential files
    mkdir -p "$ROOTFS_DIR/usr/local/bin" "$ROOTFS_DIR/etc" "$ROOTFS_DIR/root"
    echo "nameserver 1.1.1.1" > "$ROOTFS_DIR/etc/resolv.conf"

    echo "--- Step 3: Downloading PRoot ---"
    PROOT_URL="https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"
    wget --no-check-certificate -O "$ROOTFS_DIR/usr/local/bin/proot" "$PROOT_URL"
    chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"

    touch "$ROOTFS_DIR/.installed"
    echo "Installation Complete!"
fi

# 4. Launch
if [ ! -f "$ROOTFS_DIR/bin/bash" ]; then
    [ -f "$ROOTFS_DIR/usr/bin/bash" ] && ln -s /usr/bin/bash "$ROOTFS_DIR/bin/bash"
fi

clear
echo "Ubuntu 22.04 (ARM64) starting..."
"$ROOTFS_DIR/usr/local/bin/proot" \
  --rootfs="${ROOTFS_DIR}" \
  --link2symlink \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc -b /etc/resolv.conf \
  --kill-on-exit \
  /bin/bash
