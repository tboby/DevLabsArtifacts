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
    runuser -l $TARGET_USER -c 'nvm install node | bash'
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


echo "Done."
