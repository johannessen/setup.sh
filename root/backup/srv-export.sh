#! /bin/bash
#set -e
#set -x

# Create the backup tarball and store it locally.
# Inverse script: backup/import.sh


BACKUPDIR=/root/backup/files
BACKUPSRVFILE=srv.tar

. /root/backup/credentials


mkdir -p "$BACKUPDIR"
cd "$BACKUPDIR"
date >> backuptimestamp
hostname > backuphostname
rm -f "$BACKUPSRVFILE" databases.tar
tar -cf "$BACKUPSRVFILE" backuptimestamp backuphostname



# srv.tar
# this is for:
# - volatile / transient data (such as temp/dev files)
# - large binaries that are not in repositories
# - files that are not in repositories for legal reasons

tar_append () {
  if [ -e "$2" ]
  then 
    tar -rf "$1" "$2"
  fi
}

tar -cf "$BACKUPSRVFILE" "backuptimestamp"
cd /srv
#tar -cf "$BACKUPDIR/$BACKUPSRVFILE" --exclude=Data --warning=no-file-changed *

# append server files that need to be appended ...



cd "$BACKUPDIR"
rm -f backuptimestamp backuphostname
