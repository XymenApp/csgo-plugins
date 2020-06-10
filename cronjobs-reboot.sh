#/home/csgoserver/csgoserver start > /dev/null 2>&1
#
#
#
if [ ! -d "webserver" ]; then
    mkdir webserver
fi
if [ ! -d "webserver/logs" ]; then
    mkdir webserver/logs
fi
if [ ! -f "webserver/logs/start.log" ]; then
    echo "Log Created at `date`" > webserver/logs/start.log
fi
echo "-----------------------------------------" >> webserver/logs/start.log
echo "-----------------------------------------" >> webserver/logs/start.log
echo "-----------------------------------------" >> webserver/logs/start.log
echo "cronjobs-reboot started at `date`" >> webserver/logs/start.log
./csgoserver start >> webserver/logs/start.log
./csgoserver-2 start >> webserver/logs/start.log
./csgoserver-3 start >> webserver/logs/start.log
echo "cronjobs-reboot finished at `date`" >> webserver/logs/start.log
echo "-----------------------------------------" >> webserver/logs/start.log
echo "-----------------------------------------" >> webserver/logs/start.log
echo "-----------------------------------------" >> webserver/logs/start.log