#!bash


# Start Apache and clean up

echo "Apache done."

rm "$BACKUPSRVPATH"
rm -f /var/www/.wp-cli/cache/core/wordpress-*.tar.gz /var/www/.wp-cli/cache/plugin/*.zip /var/www/.wp-cli/cache/theme/*.zip

if apachectl configtest
then
  systemctl start apache2
  if systemctl is-active apache2
  then
    apachectl graceful
  else
    apachectl start
  fi
fi



### Perl
# Building & installing Perl is ridiculously slow. It might be preferable to
# get postfix up and running ASAP, then perhaps Apache to be able to at least
# serve static pages, and only then start brewing Perl and stuff. Also, we must
# ensure that Apache behaves as it should during this state. Either 503s need
# to be served or the server shouldn't be running at all.

# A reboot before brewing perl may be useful to be sure it picks up the new host name. -- TODO: I think I got this from some guide, but it seems to be BS. Remove this comment unless issues surface soon!

setup_copy /root/perlbrew.sh X

/root/perlbrew.sh perl-5.32.0

[ -z "$PERLBREW_ROOT" ] && . /opt/perlbrew/etc/bashrc
export TESTING="--notest"

# at this point (before installing modules) the system takes up approx. 3 GB on disk
# /root will eventually take up at least another 3 GB (due to backups)

# some XS modules require additional packages for linking
DEBIAN_FRONTEND=noninteractive apt-get -y install libssl-dev libmariadbclient-dev
cpanm $TESTING IO::Socket::SSL DBD::MariaDB || SETUPFAIL=810
#cpanm --notest DBD::mysql || SETUPFAIL=811  # --notest: incompatibilities between MariaDB and MySQL may show up



rm -Rf /root/.cpanm/work /root/.cpanm/latest-build /root/.cpanm/build.log
rmdir /root/.cpanm || true

echo
echo "Perl install: All done!"

