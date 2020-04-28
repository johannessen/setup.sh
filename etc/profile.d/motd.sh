# /etc/profile.d/motd.sh



# Print info on current MTA mail queue. This is supposed to alert privileged
# users to the MTA being clogged by undeliverable messages (which did occur
# *once* back on Tay, meaning this solution is probably way over-engineered).
if groups | grep -q 'wheel' || whoami | grep -q '^root$'
then
	MAILQ=`which mailq &> /dev/null && mailq 2> /dev/null`
	if [[ $? -ne 0 || `echo "$MAILQ" | wc -c` -le 1 ]]
	then
		echo -n 'Mail queue is not available.'
	else
		# colorize abnormal condition
		if echo -n "$MAILQ" | grep -vq ' empty'
		then
			#echo -ne '\e[1m'  # just bold
			echo -ne '\e[1;35m'  # dark magenta
			#echo -ne '\e[1;94m'  # light blue
			#echo -ne '\e[1;32m'  # dark green
			#echo -ne '\e[1;91m'  # red
			#echo -ne '\e[1;95m'  # light magenta
		fi
		
		echo -n "$MAILQ" | sed -e '$ ! d' -e 's/^-- /Mail queue: /' -e 's/ empty/ empty./'
		
		# make sure to go back to black
		echo -ne '\e[0m'
	fi
fi



# The following is info on the current user's mail box. Unless an abnormal
# condition exists, this is expected to say "no mail" because mail should be
# delivered to individual users by outgoing email forwarding. This info is
# supposed to be basically the same thing that sshd already provides, but I
# wanted this to be on the same line as the MTA mail queue info above to save
# screen space.
# If the MTA queue info above is disabled, then this should probably be
# disabled, too, in favour of the appropriate option "pam_mail.so standard"
# in /etc/pam.d/sshd. (NB. By default that option seems to be set on Cat, but
# it might be overridden elsewhere. The default config says "noenv" = not to
# set $MAIL, but it is set. The "nopen" option should disable printing the mail
# box info, but set $MAIL. Or comment the entire line and be done with it.)

if which mail > /dev/null
then
  # `mail` requires the mailutils package, but that seems unmaintained and
  # actually segfaults in buster. What happens in this situation is probably
  # that local mails gets written to /var/mail/<user>, along with a console
  # message like this:
  # You have mail in /var/mail/root
  
  echo -n ' '
  if echo 'x' | mail &>/dev/null
  then
    # x means 'quit without saving'. mail will return an error code if there is no
    # mail. That error code is all we're interested in.
    # :TODO: check out `mail -e`
    
    echo -ne '\e[1;91mYou have mail!\e[0m'  # red
    #echo -ne '\e[1;95mYou have mail!\e[0m'  # light magenta
    #echo -ne '\e[1mYou have mail!\e[0m'  # just bold
    #echo -ne '\e[1;32mYou have mail!\e[0m'  # dark green
    #echo -ne '\e[1;35mYou have mail!\e[0m'  # dark magenta
    #echo -ne '\e[1;94mYou have mail!\e[0m'  # light blue
  else
    echo -n 'No mail.'
  fi
fi
echo



# this isn't portable, but seems to work fine on GNU/Linux
echo "Welcome to `hostname -s | sed -e 's/^./\u&/'`!"
