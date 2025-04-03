#!/bin/bash

# Updated - 03 April 2025
### Script to backup source directory to destination

# Make sure that this script is not source but executed directly
# As sourcing it will run the script in the current shell
# This will make sure that exported variables or trap settings are not left behind
if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
    echo "Don't source this file. Execute it."
    return 1
fi

# Adjustable Variables
SRC="/path/to/backup/source"
EXCLUDE="lost+found"
DEST="/path/to/destination"
DATE=$(date +"%Y-%m-%d-%H-%M-%S")
BACKUP_NAME="name_of_backup"
BACKUP_TARGET="$DEST/${BACKUP_NAME}_$DATE"  # Final Backup location + Name
LOGFILE="/tmp/${BACKUP_NAME}_rsync_${DATE}.log"
LOCKFILE="/tmp/rsync_backup.lock"
MAX_BACKUPS=2


# Function to check if another rsync process is running
check_running_rsync() {
    # Log
    echo -e "Checking if there is any existing rsync backup..." >> "$LOGFILE"
    # Check lock file existence
    if [ -e "$LOCKFILE" ]; then
        echo "Another rsync process is still running. Exiting..." >> "$LOGFILE"
        exit 1
    fi
    # No lock file found
    echo -e "No existing rsync process found. Proceeding..." >> "$LOGFILE"
}


# Function to cleanup and remove lockfile
# In the event that script exits (normal or error) 
cleanup() {
    echo "Cleaning up and removing lockfile." >> "$LOGFILE"
    rm -f "$LOCKFILE"
}

# Register cleanup function to be called on script exit
trap cleanup EXIT


# Function to determine the backup target
get_backup_target() {
    # Count the number of existing backups
    echo -e "Checking the number of existing backups..." >> "$LOGFILE"
    backup_count=$(find $DEST -maxdepth 1 -name "${BACKUP_NAME}*" -type d 2>/dev/null | wc -l)

    # If exceed max count, replace the oldest copy
    if [ "$backup_count" -ge "$MAX_BACKUPS" ]; then
        echo -e "Existing backups already reach maximum count.\nLooking to replace the oldest copy..." >> "$LOGFILE"

        # Due to the backup naming convention, sort will get the oldest copy
        oldest_backup=$(find $DEST -maxdepth 1 -name "${BACKUP_NAME}*" -type d | sort | head -1)
        # Use the directory of the oldest copy as the destination
        echo -e "Replacing $oldest_backup with new backup: $BACKUP_TARGET" >> "$LOGFILE" 
        mv $oldest_backup $BACKUP_TARGET
    else
        # Create the backup target directory
        echo -e "Creating new backup directory: $BACKUP_TARGET." >> "$LOGFILE"
        mkdir -p "$BACKUP_TARGET"
    fi

}

###### Logic starts here

# Check if rsync is present
# &> supresses output
if ! command -v rsync &>; then
    echo -e "rsync command not found, please install it...\n dnf/yum install -y rsync" >> "$LOGFILE"
    exit 1
fi

# Check for running rsync processes
check_running_rsync

# Validate source directory
if [ ! -d "$SRC" ]; then
    echo -e "Source directory $SRC does not exist. Exiting..." >> "$LOGFILE"
    exit 1
fi

# Create lockfile
# If lockfile cannot be created - terminate script
if ! touch "$LOCKFILE"; then
    echo "Failed to create lockfile. Exiting." >> "$LOGFILE"
    exit 1
fi

# Function check will determine the backup target (either reuse the oldest or create a new directory)
get_backup_target

# Start the backup using rsync
echo -e "Starting backup now at $(date)\n" >> "$LOGFILE"
echo "----------------------" >> "$LOGFILE"
# Copy everything from $SRC to $BACKUP_TARGET, keeping permissions and timestamps, and excluding the $EXCLUDE directory.
# If any files exist in the target but not in the source, delete them.
# Log everything — including errors — into $LOGFILE."
rsync -av --delete --exclude="$EXCLUDE" "$SRC" "$BACKUP_TARGET" >> "$LOGFILE" 2>&1

# Check if the rsync command was successful
if [ $? -eq 0 ]; then
    echo -e "\n----------------------" >> "$LOGFILE"
    echo "Backup completed successfully at $(date)" >> "$LOGFILE"
else
    echo -e "\n----------------------" >> "$LOGFILE"
    echo "Backup encountered errors at $(date)" >> "$LOGFILE"
fi

# Logging script termination/completion
echo "Backup script finished at $(date)" >> "$LOGFILE"
