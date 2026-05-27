# Script to install NVM on Linux package on Azure DevTest lab Linux VMs.
#
# NOTE: Intended for use by the Azure DevTest Lab artifact system.
#
# Usage: 
#
# linux_install_nvm_v1.sh TARGET-USER
#

#!/bin/bash

#Get the input parameter value.
TARGET_USER=$1
LOG_FILE="/var/log/linux_install_nvm_v1.log"
exec >> "$LOG_FILE" 2>&1
echo "Started at $(date)" 
# Check if nvm is already installed.
echo "Checking if NVM is already installed."
echo "For user $TARGET_USER"
runuser -l $TARGET_USER -c 'nvm -v'
installationStatus=$(echo $?)

if [ $installationStatus -eq 127 ] ; then
    echo "Installing NVM..."
    runuser -l $TARGET_USER -c 'wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash'
    echo "Installed NVM for user $TARGET_USER."
    runuser -l "$TARGET_USER" -c 'export NVM_DIR="$HOME/.nvm"; . "$NVM_DIR/nvm.sh"; nvm install node; nvm alias default node'  
    echo "Installed Node for user $TARGET_USER."
    
else
    echo "NVM is already installed."
fi

# Check if uv is already installed.
echo "Checking if uv is already installed."
echo "For user $TARGET_USER"
runuser -l $TARGET_USER -c 'uv --version'
installationStatus=$(echo $?)

if [ $installationStatus -eq 127 ] ; then
    echo "Installing UV..."
    runuser -l $TARGET_USER -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
    echo "Installed UV for user $TARGET_USER."
else
    echo "UV is already installed."
fi

groupadd -f docker
usermod -aG docker "$TARGET_USER"
systemctl enable --now docker

echo "Added $TARGET_USER to docker group."

FILE_SHARE_HOST=$2
FILE_SHARE_NAME=$3
STORAGE_ACCOUNT="${FILE_SHARE_HOST%%.*}"
MOUNT_POINT="/mount/${FILE_SHARE_NAME}"
NFS_PATH="${FILE_SHARE_HOST}:/${STORAGE_ACCOUNT}/${FILE_SHARE_NAME}"

if ! command -v mount.aznfs >/dev/null 2>&1; then
    echo "Installing aznfs."
    curl -sSL -O "https://packages.microsoft.com/config/$(source /etc/os-release && echo "$ID/$VERSION_ID")/packages-microsoft-prod.deb"
    dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    apt-get update
    apt-get install -y aznfs
fi

mkdir -p "$MOUNT_POINT"

if ! grep -q "$MOUNT_POINT" /etc/fstab; then
    echo "$NFS_PATH $MOUNT_POINT aznfs vers=4,minorversion=1,sec=sys,nconnect=4,_netdev,nofail 0 0" >> /etc/fstab
fi

mount "$MOUNT_POINT"

echo "Mounted $NFS_PATH at $MOUNT_POINT."

echo "Done."
