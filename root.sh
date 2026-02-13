#!/bin/sh

ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=5
timeout=10
ARCH=$(uname -m)

# 1. Architecture Detection
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}\n"
  exit 1
fi

if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                Ubuntu 22.04 INSTALLER"
  echo "#"
  echo "#######################################################################################"

  read -p "Do you want to install Ubuntu 22.04? (YES/no): " install_ubuntu
fi

case $install_ubuntu in
  [yY][eE][sS])
    echo "Downloading Ubuntu 22.04 RootFS..."
    # Updated URL for Ubuntu 22.04
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
      "http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-${ARCH_ALT}.tar.gz"
    tar -xf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"
    ;;
  *)
    if [ ! -e "$ROOTFS_DIR/.installed" ]; then
        echo "Exiting."
        exit 0
    fi
    ;;
esac

# 2. Setup PRoot
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  mkdir -p "$ROOTFS_DIR/usr/local/bin"
  echo "Downloading PRoot..."
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$ROOTFS_DIR/usr/local/bin/proot" "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"

  if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
    chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"
  else
    echo "Failed to download PRoot binary."
    exit 1
  fi
fi

# 3. Finalize Installation
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "${ROOTFS_DIR}/etc/resolv.conf"
  rm -f /tmp/rootfs.tar.gz
  touch "$ROOTFS_DIR/.installed"
fi

# 4. Display Completion and Launch
CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET_COLOR='\e[0m'

clear
echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
echo -e ""
echo -e "           ${CYAN}-----> Ubuntu 22.04 Started ! <----${RESET_COLOR}"
echo -e "${WHITE}___________________________________________________${RESET_COLOR}"

# Launch Ubuntu 22.04
"$ROOTFS_DIR/usr/local/bin/proot" \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc -b /etc/resolv.conf \
  --kill-on-exit \
  /bin/bash
