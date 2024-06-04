#!/bin/bash

# Constants
MAX_LINES=1440
LOG_PATH=/var/log/docker-stats
LOG_FILE=${LOG_PATH}/docker.stats.log
BACKUP_DIR=${LOG_PATH}/docker_backups
MAX_BACKUPS=5

mkdir -p ${LOG_PATH}

fetch_latest_stats() {
    docker stats --no-stream --format "{{json .}}" | while read -r line; do
        local timestamp=$(date +%Y-%m-%dT%H:%M:%S)
        echo "{\"timestamp\": \"$timestamp\", \"data\": $line}" >> ${LOG_FILE}
    done
}



rotate_logs() {
    mkdir -p ${BACKUP_DIR}
    local timestamp=$(date +%Y%m%d%H%M)
    mv ${LOG_FILE} ${BACKUP_DIR}/docker.stats.${timestamp}.log
    
    local num_logs=$(ls ${BACKUP_DIR} | wc -l)
    while [ ${num_logs} -gt ${MAX_BACKUPS} ]; do
        rm "${BACKUP_DIR}/$(ls -t ${BACKUP_DIR} | tail -n 1)"
        num_logs=$(ls ${BACKUP_DIR} | wc -l)
    done
}

check_and_rotate() {
    touch ${LOG_FILE}
    local line_count=$(wc -l < ${LOG_FILE})
    if [ $line_count -ge $MAX_LINES ]; then
        rotate_logs
    fi
}

main() {
    while true; do
        check_and_rotate
        fetch_latest_stats
        sleep 5
    done
}

main
