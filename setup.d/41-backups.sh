#!bash


### Set up backups

mkdir -p /root/.gnupg
chmod 700 /root/.gnupg

cd "$SETUPPATH"
shopt -s nullglob  # avoid literal '*' in case of no results
for f in root/.gnupg/*.asc
do
  setup_copy "/$f" 600
done
shopt -u nullglob  # gpg must get a parameter, and a literal '*' provides a nice error msg
gpg --batch --import /root/.gnupg/*.asc || true

# note: in case of error "error sending to agent":
#gpgconf --kill gpg-agent ; gpgconf --launch gpg-agent

setup_copy /root/.gnupg/otrust.txt 600
gpg --import-ownertrust < /root/.gnupg/otrust.txt
gpg --check-trustdb


mkdir -p /root/backup/files
chmod 700 /root/backup/files /root/backup

setup_copy /root/backup/credentials 600
sed -e "/^MYSQL_BACKUP_PASSWORD=.*/s//MYSQL_BACKUP_PASSWORD='--password=$MYSQL_BACKUP_PASSWORD'/" -i /root/backup/credentials
setup_copy /root/backup/export.sh X
setup_copy /root/backup/import.sh 744
setup_copy /root/backup/rotate.conf R
setup_copy /root/backup/srv-export.sh X
setup_copy /root/backup/srv-rotate.conf R
setup_copy /etc/cron.hourly/backup X
setup_copy /etc/cron.daily/backup-srv X



### Get transient data from backup
# Significantly this may include reading an encrypted database dump.
# May require an interactive shell for PGP passphrase input!
/root/backup/import.sh "$SETUPPATH/backup.tar" -y || SETUPFAIL=410

mysqladmin flush-privileges

