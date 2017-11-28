#!/bin/bash
# Install tools for minion to play with.

# Check dependancies
if [ ! "`which git`" ]; then 
echo "git tools are not installed, will attempt to install it now with sudo, no promises..."
sudo apt install git
echo "Done."
fi

echo "Grabbing impacket..."
git clone "https://github.com/CoreSecurity/impacket"
cd impacket
python setup.py install
cd ..
echo ""

echo "Grabbing Automated Penetration Toolkit..."
git clone "https://github.com/MooseDojo/apt2.git"
echo ""

echo "Grabbing EyeWitness..."
git clone "https://github.com/ChrisTruncer/EyeWitness.git"
echo ""

echo "Grabbing Discover scripts..."
git clone "https://github.com/leebaird/discover.git"
echo ""

echo "Grabbing MacPhish scripts..."
git clone "https://github.com/cldrn/macphish"
echo ""

echo "Grabbing WinPayloads scripts..."
git clone "https://github.com/nccgroup/winpayloads.git"
cd $PROGRAMDIR/winpayloads
sudo ./setup.sh
cd $PROGRAMDIR
echo ""

echo "Grabbing Responder, A LLMNR, NBT-NS and MDNS poisoner, with built-in HTTP/SMB/MSSQL/FTP/LDAP rogue authentication server supporting NTLMv1/NTLMv2/LMv2, Extended Security NTLMSSP and Basic HTTP authentication. Responder will be used to gain NTLM challenge/response hashes."
git clone "https://github.com/SpiderLabs/Responder.git"
echo ""

echo "Grabbing Veil Toolkit..."
git clone "https://github.com/Veil-Framework/Veil.git"
cd $PROGRAMDIR/Veil
./Install.sh -c
cd $PROGRAMDIR
echo ""

echo "Grabbing RTFM database. This provides a searchable DB of the RTFM command references..."
git clone "https://github.com/leostat/rtfm"
cd rtfm
pip install terminaltables
chmod +x ./rtfm.py 
./rtfm.py -u
cd $PROGRAMDIR
echo ""

echo "Grabbing a forked versions of PowerSploit and Powertools used in \"The Hacker Playbook 2\"."
git clone "https://github.com/cheetz/PowerSploit"
git clone "https://github.com/cheetz/PowerTools"
git clone "https://github.com/cheetz/nishang"
echo ""

echo "Grabbing a number of custom scripts written by the author of \"The Hacker Playbook 2\"."
git clone "https://github.com/cheetz/Easy-P.git"
git clone "https://github.com/cheetz/Password_Plus_One"
git clone "https://github.com/cheetz/PowerShell_Popup"
git clone "https://github.com/cheetz/icmpshock"
git clone "https://github.com/cheetz/brutescrape"
git clone "https://www.github.com/cheetz/reddit_xss"
echo ""

echo "Done."
exit 0
