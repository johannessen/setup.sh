#!bash


### install software
echo
echo "We will now install Debian software packages."
echo

apt-get update
apt-get upgrade

# Parse both installed-software lists. Empty lines and comment lines (#) are ignored.
SETUP_LOCAL_PKG=$(grep -v '^#\|^$' "$SETUPPATH/setup.apt")
SETUP_GLOBAL_PKG=$(grep -v '^#\|^$' "$SETUPPATH_GLOBAL/setup.apt")

DEBIAN_FRONTEND=noninteractive apt-get -y install $SETUP_GLOBAL_PKG $SETUP_LOCAL_PKG || exit



### handle problems with Debian packages

# Some software (such as DBD::mysql 4.050) expects to find a mysql_config
# binary on the path. MariaDB doesn't seem to provide that my default, so
# we create a link. We do so in /usr/bin, so that any future installation
# of mysql would hopefully simply replace the link with its own version.
which mysql_config > /dev/null || ln -vs mariadb_config /usr/bin/mysql_config



### install additional software

# If multiple Perls are installed on a system, it may be difficult
# to get scripts to run with a specific version in a portable way.
# By making /opt/bin/perl a link to the Perl version that we want to
# use by default, we can at least make it semi-portable. This won't
# work in foreign environments, but it will work perfectly on any
# server using this setup script. For now, system Perl is the only
# one available, so we make the link point to that until we brew.
# (Technically, this method breaks the FHS, which states that
# "Packages ... must function normally in the absence of [/opt/bin]."
# Perhaps /opt/perlbrew/bin/perl would be better?)
mkdir -p /opt/bin
ln -vs /usr/bin/perl /opt/bin/perl

# Wordpress CLI <https://wp-cli.org/>
echo "Working on wp-cli ..."
mkdir -p /opt/wp-cli
cd /opt/wp-cli
curl -LO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
ln -vs /opt/wp-cli/wp-cli.phar /usr/local/bin/wp
mkdir -p /var/www/.wp-cli/cache
chown -R www-data:www-data /var/www/.wp-cli

