echo "Creating tmp dir..."
mkdir .tmp_update
cd .tmp_update
git clone "https://github.com/jasonisgr8/minion"
cd minion
VERSION="`grep -i version minion.sh | awk -F\\" '{print $2}'`"
echo "Updating files to version $VERSION from Github..."
cp -ar tools/* ../../tools/
chmod +x ../../tools/*
cp -ar modules/* ../../modules/
chmod +x ../../modules/"*
cp minion.sh ../../
chmod +x ../../minion.sh
cp help_templates ../../
echo "Done."
echo "Cleaning up..."
cd ../../
rm -fr .tmp_update
echo "Done. The next run of your minion should be using the latest version."
