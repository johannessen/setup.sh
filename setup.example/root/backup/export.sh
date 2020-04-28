#! /bin/bash

# Create the backup tarball and store it locally.
# Inverse script: import.sh


BACKUPDIR=/root/backup/files
BACKUPFILE=backup.tar
BACKUPSRVFILE=srv.tar


mkdir -p "$BACKUPDIR"
cd "$BACKUPDIR"
date >> backuptimestamp
rm -f "$BACKUPFILE" serverconfig.tar "$BACKUPSRVFILE"
tar -cf "$BACKUPFILE" backuptimestamp

# This script must be tailored for your individual needs.
# You'll probably want to supply a matching import.sh, too.

# The 'Hello World' site doesn't use databases or much other
# server-specific config, so backup.tar stays empty here.



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

# Hello World
tar_append "$BACKUPDIR/$BACKUPSRVFILE" hello-world/index.html



cd "$BACKUPDIR"
rm -f backuptimestamp
