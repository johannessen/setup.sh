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
setup_copy /etc/postfix/access_postgrey R || true
setup_patch /etc/default/postgrey || true
setup_copy /root/postgreyreport.pl X || true

/etc/postfix/reload

