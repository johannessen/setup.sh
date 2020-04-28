#! /bin/bash
#set -e
#set -x

BACKUPFILE=backup.tar

# try to protect against accidental execution
if (whoami | grep -qv '^root$') ; then
	echo "Usage: `basename $0` $BACKUPFILE -y"
	echo "Execute as root!"
	exit 1
fi
if [[ $# -lt 2 || $# -gt 2 || ("$2" != "-y") ]] ; then
	echo "Usage: `basename $0` $BACKUPFILE -y"
	exit 1
fi

SCRIPTNAME=`basename "$0" '.sh'`
TARBALL=`readlink -m $1`
#if [ ! -f "$TARBALL" ] ; then
#	SCRIPTPWD=`pwd`
#	TARBALL="$SCRIPTPWD/$TARBALL"
#fi
if [ ! -f "$TARBALL" ] ; then
	echo "$SCRIPTNAME: $1: Cannot open: No such file or directory" 1>&2
	echo "$SCRIPTNAME: Error is not recoverable: exiting now" 1>&2
	echo
	exit 1
fi

BACKUPDIR=`mktemp -dt "${SCRIPTNAME}.XXXXXX"` || exit 1
echo "created directory: '$BACKUPDIR'"
cd "$BACKUPDIR"
tar -xf "$TARBALL" || exit 1

echo -n "importing backup"
[ -e "backuptimestamp" ] && echo -n " '`cat backuptimestamp`'"
echo

sleep 1  # give user time to see the intro
if [ -f databases.tar.gpg ] ; then
	gpg databases.tar.gpg || exit 1
fi
if [ -f serverconfig.tar.gpg ] ; then
	gpg serverconfig.tar.gpg || exit 1
fi
if [ -f serverconfig.tar.bz2 ] ; then
	bunzip2 serverconfig.tar.bz2
fi
if [ -f databases.tar ] ; then
	tar -xf databases.tar
fi
if [ -f serverconfig.tar ] ; then
	tar -xf serverconfig.tar
fi



echo "Importing Let's Encrypt accounts and certificates..."

if [ -e le-accounts ]
then
  mkdir -p /etc/letsencrypt
  mv le-accounts /etc/letsencrypt/accounts
  mv le-archive /etc/letsencrypt/archive
  mv le-renewal /etc/letsencrypt/renewal
  mv le-renewal-disabled /etc/letsencrypt/renewal-disabled
  mv le-live /etc/letsencrypt/live
  chmod 700 /etc/letsencrypt/accounts
  chmod 700 /etc/letsencrypt/archive
  chmod 700 /etc/letsencrypt/live
else
  echo "(not present in $BACKUPFILE -- skipped!)"
fi



rm -Rf "$BACKUPDIR"/*
rm -Rvf "$BACKUPDIR"

exit 0
