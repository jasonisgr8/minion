echo "Creating tmp dir..."
rm -fr .tmp_update
mkdir .tmp_update
cd .tmp_update
git clone "https://github.com/jasonisgr8/minion"
cd minion
NEWVERSION="`grep -ie \"^version\=\" ./minion.sh | awk -F\\" '{print $2}'`"
echo "Updating files to version $NEWVERSION from Github..."
cp -ar tools/* ../../tools/
chmod +x ../../tools/*
cp -ar modules/* ../../modules/
chmod +x ../../modules/*
cp minion.sh ../../
chmod +x ../../minion.sh
cp help_templates ../../
cp sample-settings.cfg ../../
cp README.md ../../
echo "Done."
echo "Cleaning up..."
cd ../../
rm -fr .tmp_update
echo "Done. The next run of your minion should be using the latest version."
