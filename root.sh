#!/bin/sh

# 1. Setup - Files kahan save hongi
ROOTFS_DIR=$(pwd)/ubuntu-fs
max_retries=5
timeout=20
ARCH=$(uname -m)

# Purani kharab files ko saaf karne ke liye
if [ -d "$ROOTFS_DIR" ] && [ ! -f "$ROOTFS_DIR/.installed" ]; then
    echo "Pichla installation incomplete tha, usey delete kar rahe hain..."
    rm -rf "$ROOTFS_DIR"
fi

# 2. Architecture Detection
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}\n"
  exit 1
fi

# 3. Installation Logic
if [ ! -e "$ROOTFS_DIR/.installed" ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                Ubuntu 22.04 INSTALLER"
  echo "#"
  echo "#######################################################################################"

  read -p "Kya aap Ubuntu 22.04 install karna chahte hain? (YES/no): " install_ubuntu

  case $install_ubuntu in
    [yY][eE][sS])
      mkdir -p "$ROOTFS_DIR"
      
      echo "Step 1: Downloading Ubuntu 22.04 RootFS..."
      ROOTFS_FILE="ubuntu-rootfs.tar.gz"
      wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$ROOTFS_FILE" \
        "http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-${ARCH_ALT}.tar.gz"

      if [ ! -s "$ROOTFS_FILE" ]; then
        echo "Error: Download fail ho gaya. Internet check karein."
        exit 1
      fi

      echo "Step 2: Extracting RootFS (Isme 1-2 minute lag sakte hain)..."
      # Extraction command with error check
      tar -xf "$ROOTFS_FILE" -C "$ROOTFS_DIR" || { echo "Error: Extraction fail ho gaya!"; exit 1; }
      
      # Cleanup download file
      rm "$ROOTFS_FILE"

      # Step 3: Create essential system folders if missing
      echo "Step 3: Setting up system directories..."
      mkdir -p "$ROOTFS_DIR/etc"
      mkdir -p "$ROOTFS_DIR/root"
      mkdir -p "$ROOTFS_DIR/dev"
      mkdir -p "$ROOTFS_DIR/sys"
      mkdir -p "$ROOTFS_DIR/proc"
      mkdir -p "$ROOTFS_DIR/tmp"
      mkdir -p "$ROOTFS_DIR/usr/local/bin"

      echo "Step 4: Setting up DNS..."
      printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > "${ROOTFS_DIR}/etc/resolv.conf"
      
      touch "$ROOTFS_DIR/.installed"
      echo "Installation Complete!"
      ;;
    *)
      echo "Exiting."
      exit 0
      ;;
  esac
fi

# 4. Setup PRoot
PROOT_BIN="$ROOTFS_DIR/usr/local/bin/proot"
if [ ! -e "$PROOT_BIN" ]; then
  echo "Step 5: Downloading PRoot..."
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O "$PROOT_BIN" "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"

  if [ -s "$PROOT_BIN" ]; then
    chmod 755 "$PROOT_BIN"
  else
    echo "Error: PRoot download fail ho gaya."
    exit 1
  fi
fi

# 5. Final Path Verification (Bash check)
if [ ! -f "$ROOTFS_DIR/bin/bash" ]; then
    if [ -f "$ROOTFS_DIR/usr/bin/bash" ]; then
        # Kuch system me bash /usr/bin me hota hai, usey link kar do
        ln -s /usr/bin/bash "$ROOTFS_DIR/bin/bash"
    else
        echo "GHASTLY ERROR: /bin/bash nahi mila. Extraction fail hui hai."
        echo "Solution: 'rm -rf ubuntu-fs' likh kar enter karein aur firse script chalayein."
        exit 1
    fi
fi

# 6. Launch Ubuntu
CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET_COLOR='\e[0m'

clear
echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
echo -e ""
echo -e "           ${CYAN}-----> Ubuntu 22.04 Started ! <----${RESET_COLOR}"
echo -e "${WHITE}___________________________________________________${RESET_COLOR}"

# PRoot Launch Command
# --link2symlink: Android/Termux/Cloud systems ke liye zaroori hai
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
