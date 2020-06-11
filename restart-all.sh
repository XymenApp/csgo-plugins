#/home/csgoserver/csgoserver r > /dev/null 2>&1
#
#
#
echo "Restarting..."
./csgoserver r > /dev/null 2>&1
echo "1st Server Restarted"
./csgoserver-2 r > /dev/null 2>&1
echo "2nd Server Restarted"
./csgoserver-3 r > /dev/null 2>&1
echo "3rd Server Restarted"