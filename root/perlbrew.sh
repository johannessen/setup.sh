#! /bin/bash


export PERLBREW_ROOT=/opt/perlbrew

if ! which perlbrew > /dev/null && [ -e "$PERLBREW_ROOT/etc/bashrc" ]
then
  . "$PERLBREW_ROOT/etc/bashrc"
fi

if ! which perlbrew > /dev/null
then
  echo "init perlbrew ..."
  curl -kL https://install.perlbrew.pl | bash
  echo "source $PERLBREW_ROOT/etc/bashrc" >> /root/.bashrc
  . "$PERLBREW_ROOT/etc/bashrc"  # note sure if this is enough ... the docs require a new shell
  perlbrew init
  echo "perlbrew installion complete. You may need to open a new shell."
fi

if [ -z "$1" ]
then
  # If invoked without args, one option might be to install the newest
  # stable perl version. But getting that version number seems non-trivial.
  echo "perlbrew available:"
  perlbrew available
  exit 1
fi

#mkdir -p /opt/perlbrew
#cd /opt/perlbrew
#curl -LO https://cpan.metacpan.org/authors/id/G/GU/GUGOD/App-perlbrew-0.88.tar.gz
#tar -xzf App-perlbrew-*.tar.gz
#mv App-perlbrew-*/lib .
#rm -Rf App-perlbrew-*

#PERL_INSTALL_VERSION=$( perlbrew available | grep perl-5.30 | cut -b 3- )
#PERL_INSTALL_VERSION=perl-5.30.2
PERL_INSTALL_VERSION="$1"
echo "$1" | grep -q "perl" || PERL_INSTALL_VERSION="perl-$1"



echo -n "Beginning to brew $PERL_INSTALL_VERSION: "
date

if which apt-get > /dev/null && ! which gcc make > /dev/null
then
  DEBIAN_FRONTEND=noninteractive apt-get -y install gcc make
fi

# On dual core CPUs (like Solent), 2 jobs save a *lot* of time, while even more jobs save very little.
BREW_JOBS=3
perlbrew install -j "$BREW_JOBS" "$PERL_INSTALL_VERSION" || exit 21
#perlbrew use "$PERL_INSTALL_VERSION"  # 'use' means this session only
perlbrew switch "$PERL_INSTALL_VERSION"

# update the bin/perl link
mkdir -p /opt/bin
if [ ! -e /opt/bin/perl ] || [ "$(realpath /opt/bin/perl)" = "/usr/bin/perl" ]
then
  rm -f /opt/bin/perl
  ln -vs "/opt/perlbrew/perls/$PERL_INSTALL_VERSION/bin/perl" /opt/bin/perl
fi

echo -n "Finished brewing Perl: "
date



export TEST_JOBS="$BREW_JOBS"
export TESTING="--notest"
curl -L https://cpanmin.us | perl - App::cpanminus

cpanm $TESTING App::cpanoutdated
echo "Updating dual life modules:"
cpan-outdated --verbose | sed -e 's/ *[^ ]*$//'
cpan-outdated | cpanm $TESTING

# The brew tends to fail on the first try. As a last resort, --notest should help:
# perlbrew --notest install perl-stable
# perlbrew --force install perl-stable

# Actually, there is an argument to be made for always installing with --notest:
# <http://www.modernperlbooks.com/mt/2012/01/speed-up-perlbrew-with-test-parallelism.html#comment-1158>
