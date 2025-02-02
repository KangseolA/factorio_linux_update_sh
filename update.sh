#!/bin/bash

# Variables
factorio_package=/opt/factorio/update/factorio_headless
factorio_package_past=/opt/factorio/update/factorio_headless_past
factorio_binary=/opt/factorio/bin/x64/factorio
factorio_server_settings=/opt/factorio/data/server-settings.json
factorio_saves=/opt/factorio/saves/20241205.zip
current_date=$(date '+%Y%m%d%H')
log_file="/opt/factorio/logs/$current_date.log"

# Check running factorio PID
factorio_PID=$(ps -ef | grep -i '[b]in/x64/factorio' | awk '{print $2}')

# Backup old version for diff
cp -f $factorio_package $factorio_package_past

# Download new version
if ! wget -O $factorio_package https://factorio.com/get-download/stable/headless/linux64; then
    echo "Failed to download the Factorio package. Aborting..."
    exit 1
fi

# diff
if [ "$(sha256sum $factorio_package $factorio_package_past | awk '{print $1}' | uniq | wc -l)" -eq 1 ]; then
    echo "Versions are identical. Aborting..."
    exit 1
else
    echo "Versions are different. Proceeding..."
fi

# Extract new version
if ! tar -xJf $factorio_package -C /opt; then
    echo "Failed to extract the Factorio package. Aborting..."
    exit 1
fi

# Shutdown running factorio server
if [ -n "$factorio_PID" ]; then
    echo "Stopping Factorio process with PID: $factorio_PID"
    kill $factorio_PID
    sleep 7  # Grace period for the process to terminate
    if ps -p $factorio_PID > /dev/null; then
        echo "Process did not terminate. Forcing shutdown..."
        kill -9 $factorio_PID
    fi
else
    echo "No running Factorio process found."
fi

#excute new version
nohup $factorio_binary --server-settings $factorio_server_settings --start-server $factorio_saves > "$log_file" 2>&1 &
if [ $? -eq 0 ]; then
    echo "Factorio server started successfully. Logs are saved in $log_file"
else
    echo "Failed to start the Factorio server. Check logs in $log_file for details."
    exit 1
fi
