#!bash


# Many of the tools these scripts run are only available on Debian Linux
# (e. g. apt). So there is not even a point in trying on e. g. Darwin.
[ `uname` = 'Linux' ] || { echo "ERROR: Can't run on `uname`, requires Linux." ; exit 1 ;}



# see setup.manual/locale.txt
export LANG=
export LC_CTYPE=C.UTF-8
update-locale LANG= LC_CTYPE=C.UTF-8 LC_COLLATE=C LC_NUMERIC=C



### user prefs

setup_copy /etc/skel/.bashrc X

setup_patch /etc/bash.bashrc
setup_patch /root/.bashrc



### user accounts

setup_copy /etc/sudoers.d/wheel 0440
addgroup --gid 500 wheel
adduser root wheel

. "$SETUPPATH/credentials.private"

setup_user_accounts || true



### SSH

setup_patch /etc/ssh/sshd_config



### hostname and login message

setup_copy /etc/motd R
setup_copy /etc/profile.d/motd.sh X
setup_copy /etc/init.d/hostname_vps X

if [ -z "$HOSTNAME_VPS" ]
then
  echo "\$HOSTNAME_VPS not set."
  echo "Skipping update-rc.d hostname_vps."
else
  echo "$HOSTNAME_VPS" > /etc/default/hostname_vps
  update-rc.d hostname_vps defaults 09
  /etc/init.d/hostname_vps
fi

# If dist-upgrading to sid is intended, an appropriate time to do so would be
# after this step, and after all the user accounts have been created locally.



### IPv6
setup_copy /etc/network/interfaces.d/ip6 R
sed -e "s/2001:db8::163/$SETUP_DNS_AAAA/" -i /etc/network/interfaces.d/ip6
# may also require activation in Server Control Panel and a cold reboot

