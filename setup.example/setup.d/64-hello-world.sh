#!bash


echo "Installing 'Hello World' site ..."

cd /srv
mkdir hello-world
tar -xf "$BACKUPSRVPATH" hello-world/index.html

# $APACHE_DIR was set to "/etc/apache2" in 61-apache.sh

setup_copy "$APACHE_DIR/sites-available/helloworld.conf" R
setup_copy "$APACHE_DIR/sites-available/helloworld.include" R
a2ensite -q helloworld

apachectl restart

