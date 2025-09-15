#!/bin/bash -eu

echo "[INFO] Checking if Cloud-Init has completed"
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
    echo "[INFO] Waiting for Cloud-Init to finish"
    sleep 1
done

echo "[INFO] Cloud-Init has completed successfully!"
