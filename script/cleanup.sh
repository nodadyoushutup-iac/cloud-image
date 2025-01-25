#!/bin/bash -eu

echo "[INFO] Starting system cleanup"

echo "[INFO] Removing SSH keys used for building"
rm -f /home/packer/.ssh/authorized_keys /root/.ssh/authorized_keys || echo "[ERROR] Failed to remove SSH keys"

echo "[INFO] Clearing out machine ID"
truncate -s 0 /etc/machine-id || echo "[ERROR] Failed to clear machine ID"

echo "[INFO] Removing contents of /tmp and /var/tmp"
rm -rf /tmp/* /var/tmp/* || echo "[ERROR] Failed to remove temporary files"

echo "[INFO] Truncating logs that have built up during the install"
find /var/log -type f -exec truncate --size=0 {} \; || echo "[ERROR] Failed to truncate logs"

echo "[INFO] Cleaning up bash history"
rm -f /root/.bash_history /home/packer/.bash_history || echo "[ERROR] Failed to clean up bash history"

echo "[INFO] Removing /usr/share/doc contents"
rm -rf /usr/share/doc/* || echo "[ERROR] Failed to remove /usr/share/doc contents"

echo "[INFO] Removing /var/cache contents"
find /var/cache -type f -exec rm -rf {} \; || echo "[ERROR] Failed to remove /var/cache contents"

echo "[INFO] Cleaning up apt cache"
sudo apt-get -y autoremove || echo "[ERROR] Failed to autoremove apt packages"
sudo apt-get clean || echo "[ERROR] Failed to clean apt cache."
sudo rm -rf /var/lib/apt/lists/* || echo "[ERROR] Failed to remove apt lists"

echo "[INFO] Forcing a new random seed to be generated"
rm -f /var/lib/systemd/random-seed || echo "[ERROR] Failed to remove random seed"

echo "[INFO] Clearing wget history"
rm -f /root/.wget-hsts || echo "[ERROR] Failed to clear wget history"

echo "[INFO] Clearing bash history environment variable"
export HISTSIZE=0

echo "[INFO] Changing group ID for packer to 62778"
sudo groupmod -g 62778 packer || echo "[ERROR] Failed to change group ID for packer"

echo "[INFO] Changing user ID for packer to 62778"
sudo usermod -u 62778 -g 62778 packer || echo "[ERROR] Failed to change user ID/group for packer"

echo "[INFO] Removing the password for packer user"
sudo passwd -d packer || echo "[ERROR] Failed to remove password for packer user"

echo "[INFO] System cleanup completed successfully!"
