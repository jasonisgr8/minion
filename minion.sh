#!/bin/bash
# By Jason

# Package requirements: ssh, heirloom-mailx, nmap, expect, fromdos (tofrodos)
# Run "./minion.sh loop" to have it run every 2 minutes for auto-email management
# 
VERSION="3.6"
# Version History
# 3.6 - Fixed first run log file bug
# 3.5 - Added "loop" to have minion run itself every 2 minutes to replace slavedriver.sh
# 3.4 - Fixed bug in authorization email process and removed DEFAULT_RECIPIENT
# 3.3 - More cleanup
# 3.2 - Starting cleanup
# 3.1 - Initial Git release
source ./settings.cfg
MODULES="`ls -1 $MODULEFOLDER`"
#export $FILES

# check Root
if [ "$UID" = "0" ]; then
echo "I have adequate permissions, continuing on..."
else echo "I am not root, lets try one more time with sudo..."
sudo $0 $1
exit 0
fi

if [ "$1" == "loop" ]; then
while :
do
	echo "Running $0 in a 2 minute loop..."
	$0
	sleep 2m
	echo "Checking..."
done
exit 0
fi

#Create unique logging stamp
MY_STAMP="`date +%H%M%S`"
MINION_TASK=$TRIGGER-$MY_STAMP
SYSTEM_LOG="./logs/minion.log"
mkdir ./logs
touch $SYSTEM_LOG

rm -f "$MINION_TASK.log"
touch "$MINION_TASK.log"

echo "Running sequence number $MINION_TASK ..." >> "$SYSTEM_LOG"


GETNEWMAIL=$( 
SLEEP_TIME=1; 
openssl s_client -crlf -quiet -connect $IMAPSVR:$IMAPSVR_PRT -CApath /etc/ssl/certs < <( 
sleep ${SLEEP_TIME}; echo ". LOGIN $USERNAME $PASSWORD"; 
sleep ${SLEEP_TIME}; echo ". SELECT INBOX";
sleep ${SLEEP_TIME}; echo ". fetch 1:* full";
sleep ${SLEEP_TIME}; echo ". logout"; 
sleep ${SLEEP_TIME}; echo ""; 
) 
)

process_email_requests()
{
GETREQUESTMAIL=$(
SLEEP_TIME=1;  
openssl s_client -crlf -quiet -connect $IMAPSVR:$IMAPSVR_PRT -CApath /etc/ssl/certs < <( 
sleep ${SLEEP_TIME}; echo ". LOGIN $USERNAME $PASSWORD"; 
sleep ${SLEEP_TIME}; echo ". SELECT INBOX";
sleep ${SLEEP_TIME}; echo ". fetch $EACH uid";
sleep ${SLEEP_TIME}; echo ". fetch $EACH body[1]";
sleep ${SLEEP_TIME}; echo ". logout"; 
sleep ${SLEEP_TIME}; echo ""; 
) 
)

echo "$GETREQUESTMAIL" 
}

AUTH_FILE=".authorization_pending"
touch $AUTH_FILE
AUTH_MAIL=".auth_mail.$MINION_TASK"

AUTHORIZATION_REQUEST()
{
#if [ -z "$AUTH_FILE" ]; then
#        echo "Generating authorization request..." >> "$SYSTEM_LOG"
#else
#        echo "Generating authorization request..." >> "$SYSTEM_LOG"
#	touch $AUTH_FILE
#	#echo "Content-Type: text/plain; charset=us-ascii" > $AUTH_MAIL
	#echo "" >> $AUTH_MAIL
#fi

AUTH_NUMBER=$[ ( $RANDOM % 20000000 )  + 10000000 ]

echo $AUTH_NUMBER >> $AUTH_FILE
echo "Authorization number $AUTH_NUMBER has been submitted for approval." >> "$SYSTEM_LOG"
#echo "" >> $AUTH_MAIL
echo "Please review the following request for approval." > $AUTH_MAIL
echo "" >> $AUTH_MAIL
echo "To approve this request, simply reply to this email and REMOVE the Re: from the subject line." >> $AUTH_MAIL
echo "" >> $AUTH_MAIL
echo "NOTE: Emails will not be processed if there is a reply Re: or forward FW: tag in the subject line of the email." >> $AUTH_MAIL
echo "" >> $AUTH_MAIL
echo "AUTHORIZATION CODE: $AUTH_NUMBER" >> $AUTH_MAIL
echo "" >> $AUTH_MAIL
echo "BEGIN REQUEST EMAIL:" >> $AUTH_MAIL
echo "" >> $AUTH_MAIL

fromdos .request_processing.$MINION_TASK
cat .request_processing.$MINION_TASK | tr -c -d '[:graph:][:blank:]\n\r\t' | grep \: >> $AUTH_MAIL
# | awk -F: '{ print $1 ":"$2 }' 

echo "" >> $AUTH_MAIL
echo "END REQUEST" >> $AUTH_MAIL

cat "$AUTH_MAIL" >> "$SYSTEM_LOG"
echo "Sending approval request to $APPROVAL_RECIPIENT..." >> "$SYSTEM_LOG"
echo "$AUTH_MAIL"
cat "$AUTH_MAIL" | sendEmail -o tls=yes -f "$USERNAME" -t "$APPROVAL_RECIPIENT" -s $SMTP_SERVER:$SMTP_PORT -xu "$USERNAME" -xp "$PASSWORD" -u "re: $MINION_TASK $TASK_TYPE (`date +%m-%d-%y`)"

cat "$MINION_TASK.log" >> "$SYSTEM_LOG"
rm -f "$MINION_TASK.log"; rm .request_processing.$MINION_TASK; rm $AUTH_MAIL
#rm -f $AUTH_MAIL
exit 0

}

AUTHORIZATION_CHECK()
{
if [ "$AUTHORIZATION_CODE" == "" ]; then
echo "There is no authorization code submitted, requesting authorization..."  >> "$SYSTEM_LOG"
	AUTHORIZATION_REQUEST

else
echo "Checking authorization code: $AUTHORIZATION_CODE ..."  >> "$SYSTEM_LOG"

touch $AUTH_FILE
if [ ! "`grep $AUTHORIZATION_CODE $AUTH_FILE`" ]; then
	AUTHORIZED="bad"
	echo "No valid authorization key was given. Submitting approval request..."  >> "$SYSTEM_LOG"
	AUTHORIZATION_REQUEST
else 
	AUTHORIZED="good"
	echo "Authorization code: $AUTHORIZATION_CODE was approved."  >> "$SYSTEM_LOG"

fi

fi
#else AUTHORIZATION_REQUEST
#AUTHORIZED="bad"


#grab auth variables
#if they exist, set the good to go variable for the module
}

if [ ! $1 ]; then
REPORT_REQUESTS="`echo "$GETNEWMAIL" | sed 's/\*/\\\*/g' | sed -e 's#<[^>]*>##g' | grep -vi "re\:" | grep -vi "fw\:" | grep -vi "seen"  | grep -i "$TRIGGER" | awk '{print $2 }' | sed 's/[\`\;\:|!@#\$%^&*()]//g'`"
else 
REPORT_REQUESTS="local"
fi

if [ ! "$REPORT_REQUESTS" ]; then
echo "Nothing for me to do. :(" >> "$SYSTEM_LOG"
rm .request_processing.$MINION_TASK $MINION_TASK.log
exit 0
fi
#echo $REPORT_REQUESTS

for EACH in $REPORT_REQUESTS; do
if [ ! $1 ]; then
echo "Processing Email Task -- $EACH." >> "$SYSTEM_LOG"
process_email_requests > .first_request_processing.$MINION_TASK
else 
echo "Processing local task request." >> "$SYSTEM_LOG"
cat "$1" > .first_request_processing.$MINION_TASK
fi

# ~~~~~~~~~~~~~~~~~~~~ Task subroutines ~~~~~~~~~~~~~~~~~~~

MODULE_BUILDER ()
{
AUTHORIZATION_CHECK
if [ "$AUTHORIZED" = "good" ]; then
echo "Initiating $TASK_TYPE..." >> "$MINION_TASK.log"
echo "Your request has been approved and is queued for execution.  Once completed, you will recieve your data." | sendEmail -o tls=yes -f "$USERNAME" -t "$RECIPIENT" -s $SMTP_SERVER:$SMTP_PORT -xu "$USERNAME" -xp "$PASSWORD" -u "re: $MINION_TASK $TASK_TYPE (`date +%m-%d-%y`)"

echo $MODGUTS >> $MODFOLDER/$NEWMOD.mod
echo $MODHELP >> help_templates

cat "$MINION_TASK.log" >> "$SYSTEM_LOG"
rm -f "$MINION_TASK.log"; rm .request_processing.$MINION_TASK; rm $AUTH_MAIL
exit 0

else
echo "Your request has been submitted for approval.  Once approved, your request will be queued for delivery." | sendEmail -o tls=yes -f "$USERNAME" -t "$RECIPIENT" -s $SMTP_SERVER:$SMTP_PORT -xu "$USERNAME" -xp "$PASSWORD" -u "re: $MINION_TASK $TASK_TYPE (`date +%m-%d-%y`)"
AUTHORIZATION_REQUEST
fi
}

# ~~~~~~~~~~~~~~~~~~~~ Identify and delegate tasks ~~~~~~~~~~~~~~~~~~~
echo "Delegating Task..." >> "$SYSTEM_LOG"
sed 's/<[^>]*>//g' .first_request_processing.$MINION_TASK | tr [:upper:] [:lower:] > .clean_request.$MINION_TASK
rm .first_request_processing.$MINION_TASK
mv .clean_request.$MINION_TASK .request_processing.$MINION_TASK
fromdos .request_processing.$MINION_TASK

# Set global options
REQUESTFILTER="awk -F: '{ print $2 }' | sed 's/^\ //g' | sed 's/[\`\;\:]//g'"
RECIPIENT="`grep -i "Recipient" .request_processing.$MINION_TASK | awk -F: '{ print $2 }' | sed 's/^\ //g' | sed 's/[\`\;\:]//g' # | awk '{ print $1 }'`"
TARGET_IP="`grep -i "Target\ IP" .request_processing.$MINION_TASK | awk -F: '{ print $2 }' | sed 's/^\ //g' | sed 's/[\`\;\:]//g'`" # | sed 's/\ //g'`"
TARGET_PORT="`grep -i "Target\ Port" .request_processing.$MINION_TASK | awk -F: '{ print $2 }' | sed 's/^\ //g' | sed 's/[\`\;\:]//g'`"
AUTHORIZATION_CODE="`grep -i "AUTHORIZATION\ CODE" .request_processing.$MINION_TASK | awk -F: '{ print $2 }' | sed 's/^\ //g' | sed 's/[\`\;\:]//g'`"
RECIPIENT="`grep -i "Recipient" .request_processing.$MINION_TASK | awk -F: '{ print $2 }' | sed 's/^\ //g' | sed 's/[\`\;\:]//g'`"
SEARCH="`grep -i "Search\:" .request_processing.$MINION_TASK | awk -F: '{ print $2 }' | sed 's/^\ //g' | sed 's/[\`\;\:]//g'`"
TARGET_DOMAIN="`grep -i "Target\ Domain" .request_processing.$MINION_TASK | awk -F: '{ print $2 }' | sed 's/^\ //g' | sed 's/[\`\;\:]//g'`"
TARGET_EMAIL="`grep -i "Target\ email" .request_processing.$MINION_TASK | awk -F: '{ print $2 }' | sed 's/^\ //g' | sed 's/[\`\;\:]//g'`"

echo "Processing Options..." >> "$SYSTEM_LOG"
echo Target IP\: $TARGET_IP >> "$SYSTEM_LOG"
echo Target Ports\: $TARGET_PORT >> "$SYSTEM_LOG"
echo Recipient\: $RECIPIENT >> "$SYSTEM_LOG"
echo Search\: $SEARCH >> "$SYSTEM_LOG"
echo Target\ Domain\: $TARGET_DOMAIN >> "$SYSTEM_LOG"
echo Target\ Email\: $TARGET_EMAIL >> "$SYSTEM_LOG"

touch .globalvariables.$MINION_TASK
echo "TARGET_IP=\"$TARGET_IP\"" >> .globalvariables.$MINION_TASK
echo "TARGET_PORT=\"$TARGET_PORT\"" >> .globalvariables.$MINION_TASK
echo "SEARCH=\"$SEARCH\"" >> .globalvariables.$MINION_TASK
echo "TARGET_DOMAIN=\"$TARGET_DOMAIN\"" >> .globalvariables.$MINION_TASK
echo "VERSION=\"$VERSION\"" >> .globalvariables.$MINION_TASK
echo "TARGET_EMAIL=\"$TARGET_EMAIL\"" >> .globalvariables.$MINION_TASK

# Special handling for email Recipients
for ADDY in `echo $EMAIL_RECIPIENTS | tr [:upper:] [:lower:]`; do
if [ "$ADDY" = "$RECIPIENT" ]; then 
	CHECK_EMAILER="good"
	fi
	done

if [ "$CHECK_EMAILER" != "good" ]; then
echo "Attempting to use $RECIPIENT Failed because it is not recognized." >> "$MINION_TASK.log"
echo "This email address is not allowed to tell me what to do, access denied." >> "$MINION_TASK.log"
echo "Emailing alert..." >> "$MINION_TASK.log"
cat "$MINION_TASK.log" | sendEmail -o tls=yes -f "$USERNAME" -t "$APPROVAL_RECIPIENT" -s $SMTP_SERVER:$SMTP_PORT -xu "$USERNAME" -xp "$PASSWORD" -u "re: $MINION_TASK $TASK_TYPE (`date +%m-%d-%y`)"
cat "$MINION_TASK.log" >> "$SYSTEM_LOG"
rm -f "$MINION_TASK.log"; rm .request_processing.$MINION_TASK; rm $AUTH_MAIL; .globalvariables.$MINION_TASK
exit 0
fi

echo "The address getting the mail is $RECIPIENT." >> "$SYSTEM_LOG"
CHECK_EMAILER="restart"

echo Recipient\: $RECIPIENT >> "$SYSTEM_LOG"

# Start processing tasks
TASK_TYPE="`grep -i "Task\ Type" .request_processing.$MINION_TASK | awk -F: '{ print $2 }' | sed 's/^\ //g' | awk -F\< '{ print $1 }' | sed 's/\=20//g' |sed 's/\=//g' |  grep -v ^$ | uniq | sed 's/[\`\;\:|!@#\$%^&*()]//g'`"
echo "This is the task type: $TASK_TYPE" >> "$SYSTEM_LOG"

if [ -x "./modules/$TASK_TYPE.mod" ]; then
echo "Initiating \"$TASK_TYPE\"..." >> "$SYSTEM_LOG"
AUTHORIZATION_CHECK
if [ "$AUTHORIZED" == "good" ]; then

echo "Initiating $TASK_TYPE" >> "$SYSTEM_LOG"
echo "Your request has been approved and is queued for execution.  Once completed, you will recieve your data." | sendEmail -o tls=yes -f "$USERNAME" -t "$RECIPIENT" -s $SMTP_SERVER:$SMTP_PORT -xu "$USERNAME" -xp "$PASSWORD" -u "re: $MINION_TASK $TASK_TYPE (`date +%m-%d-%y`)"

FILES="$TASK_TYPE_$AUTHORIZATION_CODE.$MINION_TASK"
echo "FILES=\"$FILES\"" >> .globalvariables.$MINION_TASK

chmod +x $MODFOLDER/*.mod
$MODFOLDER/$TASK_TYPE.mod >> "$MINION_TASK.log" 2>&1

#if files, then tar and ship
if [ ! "`ls -1 $FILES*`" ]; then
echo "$TASK_TYPE task completed. [Minion V$VERSION]" >> "$MINION_TASK.log"
cat "$MINION_TASK.log" | sendEmail -o tls=yes -f "$USERNAME" -t "$RECIPIENT" -s $SMTP_SERVER:$SMTP_PORT -xu "$USERNAME" -xp "$PASSWORD" -u "re: $MINION_TASK $TASK_TYPE (`date +%m-%d-%y`)"
else

/bin/tar -czf $FILES.tgz $FILES*  >> "$MINION_TASK.log"
echo "$TASK_TYPE task completed." >> "$MINION_TASK.log"
cat "$MINION_TASK.log" | sendEmail -o tls=yes -f "$USERNAME" -t "$RECIPIENT" -s $SMTP_SERVER:$SMTP_PORT -xu "$USERNAME" -xp "$PASSWORD" -u "re: $MINION_TASK $TASK_TYPE (`date +%m-%d-%y`)" -a $FILES.tgz
fi

rm -fr $FILES*

###

cat "$MINION_TASK.log" >> "$SYSTEM_LOG"
rm -f "$MINION_TASK.log"; rm .request_processing.$MINION_TASK; rm $AUTH_MAIL; rm .globalvariables.$MINION_TASK
exit 0

else
echo "Your request has been submitted for approval.  Once approved, your request will be queued for delivery." | sendEmail -o tls=yes -f "$USERNAME" -t "$RECIPIENT" -s $SMTP_SERVER:$SMTP_PORT -xu "$USERNAME" -xp "$PASSWORD" -u "re: $MINION_TASK $TASK_TYPE (`date +%m-%d-%y`)"
AUTHORIZATION_REQUEST
fi

else
echo "Not sure what you want me to do, goodbye." >> "$SYSTEM_LOG"
fi

done

cat "$MINION_TASK.log" >> "$SYSTEM_LOG"
rm -f "$MINION_TASK.log"; rm .request_processing.$MINION_TASK; rm $AUTH_MAIL; rm .globalvariables.$MINION_TASK
exit 0
