#!/bin/sh

# Setup working directory (ubuntu-fs folder banayega taki files mix na ho)
ROOTFS_DIR=$(pwd)/ubuntu-fs
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

# 2. Installation Logic
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                Ubuntu 22.04 INSTALLER"
  echo "#"
  echo "#######################################################################################"

  read -p "Do you want to install Ubuntu 22.04? (YES/no): " install_ubuntu

  case $install_ubuntu in
    [yY][eE][sS])
      echo "Creating directory: $ROOTFS_DIR"
      mkdir -p "$ROOTFS_DIR"
      
      echo "Downloading Ubuntu 22.04 RootFS..."
      wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
        "http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-${ARCH_ALT}.tar.gz"
      
      echo "Extracting RootFS (Isme thoda time lag sakta hai)..."
      tar -xzf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"
      
      # Create missing system directories
      mkdir -p "$ROOTFS_DIR/root"
      mkdir -p "$ROOTFS_DIR/dev"
      mkdir -p "$ROOTFS_DIR/sys"
      mkdir -p "$ROOTFS_DIR/proc"
      mkdir -p "$ROOTFS_DIR/tmp"
      ;;
    *)
      echo "Exiting."
      exit 0
      ;;
  esac
fi

# 3. Setup PRoot (If not exists)
PROOT_BIN="$ROOTFS_DIR/usr/local/bin/proot"
if [ ! -e "$PROOT_BIN" ]; then
  mkdir -p "$ROOTFS_DIR/usr/local/bin"
  echo "Downloading PRoot binary..."
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$PROOT_BIN" "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"

  if [ -s "$PROOT_BIN" ]; then
    chmod 755 "$PROOT_BIN"
  else
    echo "Error: PRoot download failed. Please check your internet connection."
    exit 1
  fi
fi

# 4. Finalize Installation
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo "Setting up DNS..."
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "${ROOTFS_DIR}/etc/resolv.conf"
  rm -f /tmp/rootfs.tar.gz
  touch "$ROOTFS_DIR/.installed"
  echo "Installation Complete!"
fi

# 5. Verification Check
if [ ! -f "$ROOTFS_DIR/bin/bash" ]; then
    echo "Error: /bin/bash not found in RootFS. Extraction might have failed."
    # Fix for some minimal images where bash is in /usr/bin/bash
    if [ -f "$ROOTFS_DIR/usr/bin/bash" ]; then
        ln -s /usr/bin/bash "$ROOTFS_DIR/bin/bash"
    else
        exit 1
    fi
fi

# 6. Display and Launch
CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET_COLOR='\e[0m'

clear
echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
echo -e ""
echo -e "           ${CYAN}-----> Ubuntu 22.04 Started ! <----${RESET_COLOR}"
echo -e "${WHITE}___________________________________________________${RESET_COLOR}"

# Launch Command
# Added --link2symlink for better compatibility
# Added environment variables (TERM, HOME)
"$PROOT_BIN" \
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
