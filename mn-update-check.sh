clear
#Vars
WALLET=snowgem-wallet
DAEMON=~/$WALLET/src/snowgemd
CLI=~/$WALLET/src/snowgem-cli
LATEST=2000456

#If you get errors about the wallet loading raise this limit
WAIT=60

#Check to make sure snowgemd is running
if pgrep -x "snowgemd" > /dev/null; then
        read -n1 -r -p "Snowgem is running... Press any key to continue"
else
        echo "Starting Snowgemd..."
        $DAEMON &> /dev/null
        sleep $WAIT
fi

#Check version
VERSIONCHECK=$($CLI getinfo | grep "\"version\"" | cut -d ":" -f 2 | cut -d "," -f 1 | xargs)
if [ $VERSIONCHECK == $LATEST ]; then
        echo "Nothing needed, you're on the latest version!";
        exit
else
        read -n1 -r -p "Update Needed! We'll continue from here... Press any key to continue"

#Backup
read -n1 -r -p "We will now backup your current build and start the update. This may take awhile... Press any key to continue"
mkdir ~/mn-backup
cp ~/.snowgem/snowgem.conf ~/.snowgem/masternode.conf ~/mn-backup
cp -r $WALLET ./mn-backup/$WALLET-bak

#Update
cd ~
$CLI stop
cd $WALLET
git reset --hard
git fetch origin
git rebase origin master
chmod +x zcutil/build.sh depends/config.guess depends/config.sub autogen.sh share/genbuild.sh src/leveldb/build_detect_platform
./zcutil/build.sh --disable-rust
$DAEMON -daemon
cd ~
sleep $WAIT

#verify
VERSIONCHECK2=$($CLI getinfo | grep "\"version\"" | cut -d ":" -f 2 | cut -d "," -f 1 | xargs)
if [ $VERSIONCHECK2 == $LATEST ]; then

        read -n1 -r -p "Latest version detected. Continue..."

else
        echo  "Something went wrong... You're still on the old version!"
        exit
fi

#Start in wallet
read -n1 -r -p "In your local wallet, click on Start MN and Start Alias buttons... Press any key when ready..."

#Start snowgemd
$CLI stop
sleep 10
$DAEMON -daemon
sleep $WAIT
$CLI masternodedebug

fi
