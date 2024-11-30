#!/bin/bash

function log_info {
    echo -e "\e[32m[INFO] $1\e[0m"
}

function log_error {
    echo -e "\e[31m[ERROR] $1\e[0m"
    exit 1
}
