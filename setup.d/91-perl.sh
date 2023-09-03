#!bash


# Perl
echo
echo "We will now brew Perl and install modules."
echo

# Building Perl from source and installing modules is slow. Ensure that
# all services that don't depend on these modules (postfix etc.) are up
# and running at this point. Web services that do depend on a recent
# Perl version or on one of these modules should ideally serve 503s.

# some XS modules may require additional packages for linking
DEBIAN_FRONTEND=noninteractive apt-get -y install \
  libmariadb-dev libmariadb-dev-compat libssl-dev libxml2-dev

setup_copy /root/perlbrew.sh X

if TESTING=0 /root/perlbrew.sh perl-5.38.0
then
  rm -Rf /root/.cpanm/work /root/.cpanm/latest-build /root/.cpanm/build.log
  rmdir /root/.cpanm || true
else
  echo "perlbrew.sh returned with status $?."
  SETUPFAIL=800
  false
fi

. /opt/perlbrew/etc/bashrc



echo "Perl install: All done!"

