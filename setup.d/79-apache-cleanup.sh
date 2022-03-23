#!bash


### Start Apache and clean up

echo "Apache done."

rm -f "$BACKUPSRVPATH"
rm -f /var/www/.wp-cli/cache/core/wordpress-*.tar.gz /var/www/.wp-cli/cache/plugin/*.zip /var/www/.wp-cli/cache/theme/*.zip

if apachectl configtest
then
  systemctl start apache2
  echo -n "systemctl apache2 status: "
  if systemctl is-active apache2
  then
    apachectl graceful
  else
    apachectl start
  fi
fi

# at this point, the system takes up approx. 3 GB on disk

