#! /bin/bash
set -e

SETUPDIR=setup
SETUPFILE=setup.tar


# prepare the setup archive for deployment based on a local working copy
# TODO: make this script pull a fresh copy from the git repo on the server

# usage:
#  prep.sh path/to/setup  # prep the setup at the given path
#  prep.sh  # as above, using parent of script as the path
#  prep.sh path/to/setup setup.example  # as above, additionally prepping subdir 'setup.example'


SCRIPTPWD=`pwd`
SETUPROOT="$1"
# by default, operate on the prep script's parent dir:
[ -z "$SETUPROOT" ] && SETUPROOT=`dirname "$0"`/..


SETUPTEMP=`mktemp -dt "$(basename "$0")"`
mkdir "$SETUPTEMP/$SETUPDIR"

cd "$SCRIPTPWD"
cd "$SETUPROOT"  # two steps so that both absolute and relative paths work
pwd
cp -R * "$SETUPTEMP/$SETUPDIR/"
cd "$SETUPTEMP"


prep_tar_append () {
  if [ ! -e "$2" ]
  then
    echo "skip $2"
    return 0
  fi
  tar -rLvf "$1" --exclude .DS_Store "$2"
}

prep_setup_dir () {
  # prevent inclusion of macOS resource forks
  export COPYFILE_DISABLE=true
  
  prep_tar_append "$SETUPFILE" "$1/setup.sh"
  prep_tar_append "$SETUPFILE" "$1/setup.tools"
  prep_tar_append "$SETUPFILE" "$1/setup.apt"
  
  for f in "$1/setup.d"/*
  do
     [ -f "$f" ] && prep_tar_append "$SETUPFILE" "$f"
  done
  
  prep_tar_append "$SETUPFILE" "$1/etc"
  prep_tar_append "$SETUPFILE" "$1/home"
  prep_tar_append "$SETUPFILE" "$1/opt"
  prep_tar_append "$SETUPFILE" "$1/root"
  prep_tar_append "$SETUPFILE" "$1/srv"
  
  prep_tar_append "$SETUPFILE" "$1/README.md"
  prep_tar_append "$SETUPFILE" "$1/hostkeys.sh"
}


prep_setup_dir "$SETUPDIR"
prep_setup_dir "$SETUPDIR/setup.global"
[ -z "$2" ] || prep_setup_dir "$SETUPDIR/$2"

cd "$SCRIPTPWD"
cd "$SETUPROOT"  # two steps so that both absolute and relative paths work
mv "$SETUPTEMP/$SETUPFILE" "./$SETUPFILE"
rm -Rf "$SETUPTEMP"

echo "Prepared '$SETUPROOT/$(basename "$SETUPFILE")'."


# manually on server:

# cd /root
# tar -xf setup.tar --no-same-owner --no-same-permissions
# mv backup.tar setup
# mv srv.tar setup
