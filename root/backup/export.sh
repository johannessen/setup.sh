#! /bin/bash
#set -e
#set -x

# Create the backup tarball and store it locally.
# Inverse script: backupimport.sh


BACKUPDIR=/root/backup/files
BACKUPFILE=backup.tar
BACKUPSRVFILE=srv.tar

. /root/backup/credentials


mkdir -p "$BACKUPDIR"
cd "$BACKUPDIR"
date >> backuptimestamp
rm -f "$BACKUPFILE" databases.tar "$BACKUPSRVFILE"
tar -cf "$BACKUPFILE" backuptimestamp

# installed-software log
# we don't need this in a regular backup import, but no harm including it anyway
#dpkg --get-selections > installed-software.log
#tar -rf "$BACKUPFILE" installed-software.log
#rm -f installed-software.log
dpkg-query -l | sed -e '1,5d' -e 's/^... //g' -e 's/ \+/ /g' -e 's/^\([^ ]* [^ ]*\) .*/\1/' > installed-versions.log
bzip2 -c installed-versions.log > installed-versions.log.bz2
tar -rf "$BACKUPFILE" installed-versions.log.bz2
rm -f installed-versions.log installed-versions.log.bz2

# Perl installed module versions list
# (to help track incompatibilities after updates)
#perldoc -oText perllocal 2>&1 | grep '"Module"\|VERSION\|install \|"perllocal"' > installed-perl.log
# if which perlbrew > /dev/null && perldoc -V &> /dev/null
# then
#   export PERLBREW_ROOT=/opt/perlbrew
#   export PERLBREW_HOME=/root/.perlbrew
#   source ${PERLBREW_ROOT}/etc/bashrc
#   perlbrew use > installed-perl.log
#   /usr/bin/env perldoc -t perllocal > perllocal.log
#   for M in `grep '"Module"' perllocal.log | sed -e 's/^.*" //'`
#   do
#     V=`awk "/$M/{y=1;next}y" < perllocal.log | grep VERSION | head -n 1`
#     echo "$M $V"
#   done | sort -b >> installed-perl.log
#   bzip2 -c installed-perl.log > installed-perl.log.bz2
#   tar -rf "$BACKUPFILE" installed-perl.log.bz2
#   rm -f installed-perl.log installed-perl.log.bz2 perllocal.log
# fi

# file catalogue
# we don't usually need this either, but it may come in very handy in case of catastrophic failure
(find / | grep -v '^/boot/\|^/dev/\|^/sys/\|^/proc/\|^/root/\.cpanm\?/\|^/opt/perlbrew/build/') &> cata.log
bzip2 -c cata.log > cata.log.bz2
tar -rf "$BACKUPFILE" cata.log.bz2
rm -f cata.log cata.log.bz2




# preserve the original credentials setup file
if [ -e /root/setup/credentials.private ]
then
  cp /root/setup/credentials.private credentials.private.orig
  tar -rf serverconfig.tar credentials.private.orig
fi

# add SSH host keys (to avoid false MITM warnings)
mkdir ssh
cp /etc/ssh/ssh_host_*_key ssh/
tar -rf serverconfig.tar ssh/*

# add SSL certificates (volatile b/c letsencrypt issues new ones every other month)
if [ -e /etc/letsencrypt/accounts ]
then
  cp -R /etc/letsencrypt/archive le-archive
  tar -rf serverconfig.tar le-archive
  cp -R /etc/letsencrypt/accounts le-accounts
  rm -Rf le-accounts/acme-staging*
  tar -rf serverconfig.tar le-accounts
  cp -R /etc/letsencrypt/renewal le-renewal
  cp -R /etc/letsencrypt/renewal-disabled le-renewal-disabled
  tar -rf serverconfig.tar le-renewal le-renewal-disabled
  cp -R /etc/letsencrypt/live le-live
  tar -rf serverconfig.tar le-live
fi

# DON'T encrypt serverconfig dump
bzip2 -c serverconfig.tar > serverconfig.tar.bz2
tar -rf "$BACKUPFILE" serverconfig.tar.bz2
rm -Rf credentials.private.orig ssh le-archive le-accounts le-renewal le-renewal-disabled le-live serverconfig.tar serverconfig.tar.bz2



# DO encrypt backup file once completed
rm -f "$BACKUPFILE.gpg"
eval gpg $BACKUPKEYS --encrypt "$BACKUPFILE" && rm -f "$BACKUPFILE"



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
rm -f backuptimestamp
