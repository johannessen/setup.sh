#! /bin/bash

# This script is part of the setup.sh concept, designed for Debian.
# Running it on other operating systems may produce unexpected results.

if [ "$(uname)" = "Darwin" ]
then
  : ${BREW_JOBS:=6}
  : ${PERLBREW_ROOT:=~/.perlbrew}
  : ${TASK_BELIKE:=AJNN}
  : ${TESTING:=1}
  export PERLBREW_CONFIGURE_FLAGS="-de -Duselongdouble"
fi

# On dual core CPUs, 2 jobs save a lot of time, while even more jobs save very little.
: ${BREW_JOBS:=3}
: ${PERLBREW_ROOT:=/opt/perlbrew}
export BREW_JOBS PERLBREW_ROOT

if [ -e "$PERLBREW_ROOT/etc/bashrc" ]
then
  . "$PERLBREW_ROOT/etc/bashrc"
fi

if ! which perlbrew > /dev/null
then
  echo "init perlbrew ..."
  mkdir -p "$PERLBREW_ROOT"
  curl -L https://install.perlbrew.pl | bash
  if [ "$(uname)" = "Darwin" ]
  then
    echo "Please add \`source $PERLBREW_ROOT/etc/bashrc\` to your .profile"
  else
    echo "source $PERLBREW_ROOT/etc/bashrc" >> /root/.bashrc
  fi
  . "$PERLBREW_ROOT/etc/bashrc"
  perlbrew init || exit 20
  echo "perlbrew installion complete."
fi

if [ -z "$1" ]
then
  # If invoked without args, one option might be to install the newest
  # stable perl version. Getting that version number shouldn't be hard
  # through the MetaCPAN API, but it may not be worth the effort.
  echo "perlbrew available:"
  perlbrew available
  exit 1
fi

#PERL_INSTALL_VERSION=$( perlbrew available | grep perl-5.34 | sed -e 's/ //g' )
#PERL_INSTALL_VERSION=perl-5.38.0
PERL_INSTALL_VERSION="$1"
echo "$1" | grep -q "perl" || PERL_INSTALL_VERSION="perl-$1"



echo -n "Beginning to brew $PERL_INSTALL_VERSION: "
date

if which apt-get > /dev/null && ! which gcc g++ make > /dev/null
then
  DEBIAN_FRONTEND=noninteractive apt-get -y install gcc g++ make
fi

if [ "$TESTING" = 0 ]
then
  BREW_TEST="--notest"
fi
perlbrew install $BREW_TEST -j "$BREW_JOBS" "$PERL_INSTALL_VERSION" || exit 21
perlbrew use "$PERL_INSTALL_VERSION" || exit 21
echo -n "New perl binary: "
which perl

echo -n "Finished brewing Perl: "
date

if [ ! -e /opt/bin/perl ] || [ "$(perl -MCwd -E 'print Cwd::abs_path shift' /opt/bin/perl)" = "/usr/bin/perl" ]
then
  echo "Switching to $PERL_INSTALL_VERSION ..."
  perlbrew switch "$PERL_INSTALL_VERSION" || exit 21
  echo "Updating the /opt/bin/perl link ..."
  sudo mkdir -p /opt/bin
  sudo rm -f /opt/bin/perl
  sudo ln -vs "$PERLBREW_ROOT/perls/$PERL_INSTALL_VERSION/bin/perl" /opt/bin/perl
  CPANM_TEST="--notest"
else
  echo "WARNING: /opt/bin/perl link not updated."
  # Because apparently this is a secondary installation, not a primary one.
  SECONDARY=1
  CPANM_TEST=""
fi



if [ "$TESTING" = 0 ]
then
  CPANM_TEST="--notest"
elif [ "$TESTING" = 1 ]
then
  CPANM_TEST=""
fi
export TEST_JOBS="$BREW_JOBS"
export NONINTERACTIVE_TESTING=1
export PERL_MM_USE_DEFAULT=1
perlbrew install-cpanm

if [ -z "$SECONDARY" ]
then
  # Update dual-life modules, but only for the primary installation
  # (secondary installations might be specifically for testing older versions)
  cpanm $CPANM_TEST App::cpanoutdated
  echo "Updating dual life modules:"
  cpan-outdated --verbose | sed -e 's/ *[^ ]*$//'
  cpan-outdated | cpanm $CPANM_TEST
  echo -n "Finished updates: "
  date
fi



# Install MariaDB/MySQL modules separately without testing.
# (Their test suites seem unreliable, e.g. Homebrew/MariaDB/mysql_config issue)
echo "Installing common modules for MariaDB/MySQL:"
export DBD_MYSQL_CONFIG=mariadb_config
cpanm $CPANM_TEST --installdeps DBD::MariaDB DBD::mysql
cpanm --notest DBD::MariaDB DBD::mysql

if [[ -n "$TASK_BELIKE" && "$TASK_BELIKE" != "none" ]]
then
  : ${TASK:="Task::BeLike::$TASK_BELIKE"}
fi

if [ "$TASK" = "Task::BeLike::AJNN" ]
then
  echo "Installing common modules with $TASK from GitHub:"
  TASK_DIR=`mktemp -dt "perl-modules.XXXXXX"` || exit 23
  echo "$TASK_DIR"
  cd "$TASK_DIR"
  curl -LO https://raw.githubusercontent.com/johannessen/perl-modules/main/cpanfile
  cpanm $CPANM_TEST --installdeps . || exit 23
  rm -Rf "$TASK_DIR"
  
elif [ -n "$TASK" ]
then
  echo "Installing common modules with $TASK from CPAN:"
  cpanm $CPANM_TEST --installdeps "$TASK" || exit 23
  
else
  echo "No Task requested; installing a minimal set of common modules:"
  cat <<__EOF__ | grep -v '^#' | cpanm $CPANM_TEST || exit 23
IO::Socket::SSL
Mojolicious
__EOF__
fi



echo -n "Finished brew and module installation: "
date
if [ -z "$SECONDARY" ]
then
  echo "Switched to $PERL_INSTALL_VERSION as primary perl."
  echo "You may wish to open a new terminal."
fi
CPANM_REPORTER="$PERLBREW_ROOT/perls/$PERL_INSTALL_VERSION/bin/cpanm-reporter"
if [[ -z "$CPANM_TEST" && -x "$CPANM_REPORTER" ]]
then
  echo "You may wish to consider running:"
  echo "perlbrew use $PERL_INSTALL_VERSION"
  echo "cpanm-reporter"
elif [ -n "$CPANM_TEST" ]
then
  echo "Note: No CPAN module testing was performed."
fi
