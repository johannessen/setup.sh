#!bash


### Apache
echo
echo "We will now install /srv files and configure Apache."
echo

apachectl graceful-stop || true
APACHE_DIR=/etc/apache2

for user in `awk -F':' '/^wheel/{print $4}' /etc/group | sed -e 's/,/ /g'`
do
  addgroup "$user" www-data
done

mkdir -p /srv/Log/
chown root:adm /srv/Log
chmod 750 /srv/Log
ln -s /var/log/apache2/error.log /srv/Log/error
ln -s /var/log/apache2/error.log.1 /srv/Log/error.1
setup_copy "$APACHE_DIR/conf-available/logging.conf" R
setup_copy /etc/logrotate.d/apache2-srv R

setup_patch "$APACHE_DIR/conf-available/security.conf"
setup_patch "/etc/mime.types"

a2enconf -q logging
a2disconf -q charset
a2disconf -q localized-error-pages
a2disconf -q other-vhosts-access-log
a2disconf -q serve-cgi-bin

a2enmod -q actions
#a2enmod -q auth_digest
a2enmod -q authz_groupfile
a2enmod -q cgi
a2enmod -q expires
a2enmod -q headers
a2enmod -q include
a2enmod -q rewrite
a2enmod -q proxy_http

# the following should be available by default, but let's make sure they're available anyway
a2enmod -q alias
a2enmod -q auth_basic
a2enmod -q authn_file
a2enmod -q autoindex
a2enmod -q env
a2enmod -q mime
a2enmod -q negotiation
a2enmod -q php7.3
a2enmod -q ssl

setup_copy "$APACHE_DIR/conf-available/ssl.conf" R
a2enconf -q ssl
setup_copy /etc/cron.daily/apachessl X
#setup_copy "$APACHE_DIR/sites-available/ssl-wildcard.include" R

setup_copy /srv/Default/index.ascii.shtml R
setup_copy /srv/Default/robots.txt R
a2dissite -q 000-default
mv "$APACHE_DIR/sites-available/000-default.conf" "$APACHE_DIR/sites-available/000-default.conf.orig"  # HFS compatibility
setup_copy "$APACHE_DIR/sites-available/000-Default.conf" R
setup_copy "$APACHE_DIR/sites-available/000-Default.include" R
sed -e "s/198\.51\.100\.163/$SETUP_DNS_A/" -i "$APACHE_DIR/sites-available/000-Default.include"
a2ensite -q 000-Default

apachectl configtest
apachectl start

BACKUPSRVPATH=/srv/srv.tar
ln -s "$SETUPPATH/srv.tar" "$BACKUPSRVPATH"

######## note: at this point, about 2 GB of space are used on disk

