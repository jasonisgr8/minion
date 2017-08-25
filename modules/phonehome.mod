# kill running tunnels first
echo "Closing existing Tunnels..."
OPEN_TUNNELS="`ps -ef | grep -v "grep" | grep Nf | awk {' print $2 '}`"
for each in $OPEN_TUNNELS; do
echo "Closing tunnel with PID $each ..."
kill -9 $each
echo "Done."
done

echo "Connecting Tunnel..."
/usr/bin/expect -c "
spawn /usr/bin/ssh -Nf -t jason@67.141.232.26 -R 2222:localhost:22
expect \"assword\"
send \"th1s1smyp4ssw0rd\n\"
expect \"\\#\"
send \"top\n\"
"

echo "Connection Completed Successfully. :-) "

echo "Emailing Jasons Door task results..." >> "$SYSTEM_LOG"
cat "$MINION_TASK.log" | $SENDEMAIL

cat "$MINION_TASK.log" >> "$SYSTEM_LOG"
rm -f "$MINION_TASK.log"
