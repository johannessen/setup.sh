#! /bin/bash
set -e

echo -n "Setup script started: "
date
# setup/setup.sh 2>&1 | tee setup.log.txt
# nohup setup/setup.sh | tee setup.log.txt  # doesn't work if input from stdin is required

# TODO: Should we assume that SETUPPATH is '..' by default? Maybe ... but
# that's only useful if the global setup by default actually does produce
# a working server config (which of course is the goal)!

#SETUP_DRY_RUN=${SETUP_DRY_RUN-0}

# make sure we have everything we need *before* starting the setup process
# this is important because if we don't the script may fail and leave the system in an inconsistent state, creating a need to reinstall a fresh system all over again
SETUP_PREREQ_OK=1

echo -n "Checking user ... "
[ $(id -u) = 0 ] && echo "is root." || { echo "you are not root!" ; SETUP_PREREQ_OK= ;}

echo -n "Checking for \$HOSTNAME_VPS ... "
[ ! -z "$HOSTNAME_VPS" ] && echo "found $HOSTNAME_VPS." || { echo "is unset!" ; SETUP_PREREQ_OK= ;}

setup_check_dns () {
  r=`host -t "$1" "$HOSTNAME_VPS" 2> /dev/null | sed -e 's/.* //'` || true
  [ -z "$r" ] && return 1
  echo "$r" | grep -v "^[0-9a-fA-F:]*[0-9.]*$" > /dev/null && return 1
  echo "$r" && return 0
}

echo -n "Checking for DNS A record ... "
SETUP_DNS_A=`setup_check_dns A` && echo "found $SETUP_DNS_A." || { echo "is missing!" ; SETUP_PREREQ_OK= ;}

echo -n "Checking for DNS AAAA record ... "
SETUP_DNS_AAAA=`setup_check_dns AAAA` && echo "found $SETUP_DNS_AAAA." || { echo "is missing!" ; SETUP_PREREQ_OK= ;}

echo -n "Checking for \$SETUPPATH ... "
[ ! -z "$SETUPPATH" ] && echo "is set." || { echo "is unset!" ; SETUP_PREREQ_OK= ;}

echo -n "Checking for credentials.private ... "
[ -e "$SETUPPATH/credentials.private" ] && echo "is present." || { echo "is missing!" ; SETUP_PREREQ_OK= ;}

echo -n "Checking for backup.tar ... "
[ -e "$SETUPPATH/backup.tar" ] && echo "is present." || { echo "is missing!" ; SETUP_PREREQ_OK= ;}

echo -n "Checking for srv.tar ... "
[ -e "$SETUPPATH/srv.tar" ] && echo "is present." || { echo "is missing!" ; SETUP_PREREQ_OK= ;}

[ -z "$SETUP_PREREQ_OK" ] && [ -z "$SETUPPATH" ] && echo "( Perhaps you meant to run `dirname $0`/../setup.sh? )"
[ -z "$SETUP_PREREQ_OK" ] && [ -z "$SETUP_DRY_RUN" ] && exit 1




# init

SETUPPATH_GLOBAL="$(dirname "$(realpath "$BASH_SOURCE")")"
echo "SETUPPATH=\"$SETUPPATH\""
echo "SETUPPATH_GLOBAL=\"$SETUPPATH_GLOBAL\""
cd "$SETUPPATH" ; pwd | grep -q "^$SETUPPATH$" || exit 1

#chown -R root:root "$SETUPPATH" "$SETUPPATH_GLOBAL"

. "$SETUPPATH_GLOBAL/setup.tools"


# Run all scripts in .d dirs in order. If duplicate names exist,
# only run the "local" variant, not the "global" one.
# 
# All scripts are sourced (they're run in the CURRENT Bash process,
# not a new one). The scripts may expect setup.tools to be available,
# as well as the following variables:
# - SETUPPATH_GLOBAL
# - SETUPPATH
# - SETUPFAIL
# - HOSTNAME_VPS
# - SETUP_DNS_A
# - SETUP_DNS_AAAA
# Additionally, the scripts may pass data between each other simply
# by setting shell variables the normal way. Using `export` is not
# necessary. If you run these scripts individually, this must be
# taken into account carefully.

is_runnable_setup_script () {
  [ ! -f "$1" ] && return 1
  [ ! -r "$1" ] && [ ! -x "$1" ] && return 2
  # check first line for #!sh to avoid accidents (and macOS aliases):
  read -r l < "$1"
  (echo "$l" | grep -Eqv '^#!.*sh$') && return 3
  return 0
}

setup_finished () {
  echo -n "Setup script finished: "
  date
  echo
  # prevent accidental execution:
  [ ! -z "$SETUP_DRY_RUN" ] || chmod a-x "$SETUPPATH/setup.sh" "$SETUPPATH_GLOBAL/setup.sh"
  exit 0
}

SETUP_LOCAL_DIR="$SETUPPATH/setup.d"
SETUP_GLOBAL_DIR="$SETUPPATH_GLOBAL/setup.d"
SETUPFAIL=0
shopt -s nullglob  # avoid literal '*' in case of empty dirs
for f in "$SETUP_GLOBAL_DIR"/* "$SETUP_LOCAL_DIR"/* "~~~"
do
  echo -n "`basename \"$f\"`"
  # Unix file names may contain line breaks and stuff,
  # so we use NUL bytes as separator for sorting.
  # See also: https://mywiki.wooledge.org/ParsingLs
  printf '\0'
# note: sort -n is useless with -u, as it treats non-numeric parts of the term as equal
done | LC_ALL=C sort -uz | while IFS= read -d $'\0' f
do
  
  if is_runnable_setup_script "$SETUP_LOCAL_DIR/$f"
  then
    is_runnable_setup_script "$SETUP_GLOBAL_DIR/$f" && SETUP_GLOBAL_IGNORED="; global ignored" || SETUP_GLOBAL_IGNORED=
    echo "Running setup script '$f' (local$SETUP_GLOBAL_IGNORED)."
    [ ! -z "$SETUP_DRY_RUN" ] || . "$SETUP_LOCAL_DIR/$f"
  
  elif is_runnable_setup_script "$SETUP_GLOBAL_DIR/$f"
  then
    echo "Running setup script '$f'."
    [ ! -z "$SETUP_DRY_RUN" ] || . "$SETUP_GLOBAL_DIR/$f"
  
  elif [ "$f" = "~~~" ]
  then
    setup_finished
  else
    echo "Ignoring '$f' (not a setup script)."
  fi
  [ "$SETUPFAIL" -ne 0 ] && echo "SETUPFAIL=$SETUPFAIL"  # log SETUPFAIL for each step because the next might overwrite it
done

# The option `set -e` should normally not cause an exit after a
# `while` condition fails, but for some reason, it does just that in
# this script. Therefore, any code in this position after the while
# loop is never reached. Note that set -e is highly problematic and
# non-portable, see <https://mywiki.wooledge.org/BashFAQ/105>. We
# solve this by introducing a special name "~~~" (typically sorted
# last), and use that as the marker for a successful completion.

