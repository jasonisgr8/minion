PROCCOUNT=`ps -l | wc -l`
PROCCOUNT=`expr $PROCCOUNT - 4`

if [[ $(groups) == *irc* ]]; then
ENDPROC=`cat /etc/security/limits.conf | grep "@irc" | grep nproc | awk {'print $4'}`
ENDSESSION=`cat /etc/security/limits.conf | grep "@irc" | grep maxlogins | awk {'print $4'}`
PRIVLAGED="IRC Account"
else
ENDPROC=`cat /etc/security/limits.conf | grep "*" | grep nproc | awk {'print $4'}`
ENDSESSION="Unlimited"
PRIVLAGED="Regular User"
fi

echo -e "+++++++++++++++++: System Data :+++++++++++++++++++
+ Hostname = `hostname`
+ Uptime = `uptime | sed 's/.*up ([^,]*), .*/1/'`
+ IP Addresses: 
`ifconfig | grep -v 127.0.0 | grep -i "inet\ "`
+ Memory (MB): `echo "" && free -m | grep -v +`
+ Disk Space:
`/bin/df -h`
++++++++++++++++++: User Data :++++++++++++++++++++
+ Username = `whoami`
+ Privlages = $PRIVLAGED
+ Sessions = `who | grep $USER | wc -l` of $ENDSESSION MAX
+ Processes = $PROCCOUNT of $ENDPROC MAX
++++++++++++++++++: Netstat Info :++++++++++++++++++++
`/bin/netstat -tapn`
"
if [ "`which VBoxManage`" ]; then
echo -e "
+++++++++: Running VirtualBox Machines :+++++++++++
`VBoxManage list runningvms`
"
fi
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++"

