#!/bin/bash

echo "[INFO] Starting system cleanup"

echo "[INFO] Removing SSH keys used for building"
rm -f /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys

echo "[INFO] Clearing out machine ID"
truncate -s 0 /etc/machine-id

echo "[INFO] Removing contents of /tmp and /var/tmp"
rm -rf /tmp/* /var/tmp/*

echo "[INFO] Truncating logs that have built up during the install"
find /var/log -type f -exec truncate --size=0 {} \;

echo "[INFO] Cleaning up bash history"
rm -f /root/.bash_history /home/ubuntu/.bash_history

echo "[INFO] Removing /usr/share/doc contents"
rm -rf /usr/share/doc/*

echo "[INFO] Removing /var/cache contents"
find /var/cache -type f -exec rm -rf {} \;

echo "[INFO] Cleaning up apt cache"
sudo apt-get -y autoremove
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

echo "[INFO] Forcing a new random seed to be generated"
rm -f /var/lib/systemd/random-seed

echo "[INFO] Clearing wget history"
rm -f /root/.wget-hsts

echo "[INFO] Clearing bash history environment variable"
export HISTSIZE=0
echo "[INFO] System cleanup completed successfully!"

