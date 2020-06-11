#/home/csgoserver/csgoserver update > /dev/null 2>&1
#
#
#
if [ ! -d "webserver" ]; then
    mkdir webserver
fi
if [ ! -d "webserver/logs" ]; then
    mkdir webserver/logs
fi
if [ ! -f "webserver/logs/update.log" ]; then
    echo "Log Created at `date`" > webserver/logs/update.log
fi
echo "-----------------------------------------" >> webserver/logs/update.log
echo "-----------------------------------------" >> webserver/logs/update.log
echo "-----------------------------------------" >> webserver/logs/update.log
echo "cronjobs-update started at `date`" >> webserver/logs/update.log
./csgoserver update >> webserver/logs/update.log
./csgoserver-2 r >> webserver/logs/update.log
./csgoserver-3 r >> webserver/logs/update.log
echo "cronjobs-update finished at `date`" >> webserver/logs/update.log
echo "-----------------------------------------" >> webserver/logs/update.log
echo "-----------------------------------------" >> webserver/logs/update.log
echo "-----------------------------------------" >> webserver/logs/update.log