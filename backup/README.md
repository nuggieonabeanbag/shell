A Shell script for automated backups using `rsync`, with built-in features like logging, lockfile protection, and backup rotation.
###### Summary
- Backup source directory to a destination
- Timestamped backup folders
- Keeps the latest N number of backups (Configurable)
- Excludes specific folders
- Prevents multiple instances using a lockfile
- Logs all events

###### Requirements
- Linux system with bash
- rsync installed (dnf install -y rsync or apt install rsync)

###### To use
1. Edit the script and adjust the variables under `Adjustable Variables`.
2. Make the script executable:
   $ chmod +x rsync_backup.sh
3. Schedule it with cron (example: run daily at 1AM)
   0 1 * * * /path/to/rsync_backup.sh
