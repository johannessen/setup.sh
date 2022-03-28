#!bash


### Configure MTA

setup_copy /etc/aliases R || true
setup_copy /etc/postfix/main.cf R || true
setup_copy /etc/postfix/virtual-mysql.cf R
sed -e "/^password = .*/s//password = $MYSQL_POSTFIX_PASSWORD/" -i /etc/postfix/virtual-mysql.cf
setup_copy /etc/postfix/reload X

# Don't overwrite virtual if a backup is already in place
[ -e "/etc/postfix/virtual" ] || setup_copy /etc/postfix/virtual R

echo "Configure postgrey (if available) ..."
setup_patch /etc/default/postgrey || true
setup_copy_maybe /etc/postfix/access_postgrey R
setup_copy_maybe /root/postgreyreport.pl X

if [[ -e /etc/postgrey/whitelist_clients && ! -e "$SETUPPATH/etc/postgrey/whitelist_clients" ]]
then
  # (skipped if the local setup provides a whitelist)
  echo "Updating postgrey_whitelist_clients ..."
  mkdir -p "$SETUPPATH_GLOBAL/etc/postgrey"
  curl -fsSL https://postgrey.schweikert.ch/pub/postgrey_whitelist_clients \
    -o "$SETUPPATH_GLOBAL/etc/postgrey/whitelist_clients" || \
  curl -fsSL https://raw.githubusercontent.com/schweikert/postgrey/master/postgrey_whitelist_clients \
    -o "$SETUPPATH_GLOBAL/etc/postgrey/whitelist_clients"
fi
setup_copy_maybe /etc/postgrey/whitelist_clients R

/etc/postfix/reload

