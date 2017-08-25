echo -e "
Usage Options and Email Templates:

To get started with Minion:
Send an email with "minion" in the subject line (it ignores emails with subject lines that contain RE: or FW: because it assumes those are human responses to the team that minion should ignore).

For a list of email templates, send the following in the body of the email:

Task type: help
Recipient: your.email@address.com

To update your minion send the following in the body of the email:

Task type: minionupdate
Recipient: your.email@address.com
_________________________________________________________________

The options available for the nmap task are:

Task Type: nmap

Target IP: <10.0.0.1>
                Other Target IP Examples: scanme.nmap.org, 10.13.37.0/24, 192.168.0.1; 10.0.0-255.1-254

Target Port: <25,110,143> (Optional)
                Other Target Port Examples: 22; 1-65535; U:53,111,137, 21-25,80,139,8080

Recipient: <your.email@email-address.com>


The info in <> is sample data.  Do NOT include the < or > when sending your request.  
_________________________________________________________________

The options available for the System Stats task are:

Task Type: stats

Recipient: <your.email@email-address.com>


The info in <> is sample data.  Do NOT include the < or > when sending your request.  
__________________________________________________________________

"
