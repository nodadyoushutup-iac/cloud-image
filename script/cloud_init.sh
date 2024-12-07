#!/bin/bash -eu

source /opt/logger/logger.sh

log_info "Checking if Cloud-Init has completed"
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
    log_info "Waiting for Cloud-Init to finish"
    sleep 1
done

log_info "Cloud-Init has completed successfully!"
