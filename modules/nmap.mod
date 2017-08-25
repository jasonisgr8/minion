source .modvariables

if [ "$TARGET_PORT" ]; then 
   echo "Scanning ports: $TARGET_PORT"
   /usr/bin/nmap -sS -sV -O -p $TARGET_PORT -oA $FILES $TARGET_IP
   else 
echo "Scanning default ports..."
    /usr/bin/nmap -sS -sV -O -oA $FILES $TARGET_IP
fi
