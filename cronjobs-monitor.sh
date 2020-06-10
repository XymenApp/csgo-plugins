#/home/csgoserver/csgoserver monitor > /dev/null 2>&1
#
#
#
if [ ! -d "webserver" ]; then
    mkdir webserver
fi
if [ ! -d "webserver/logs" ]; then
    mkdir webserver/logs
fi
if [ ! -f "webserver/logs/monitor.log" ]; then
    echo "Log Created at `date`" > webserver/logs/monitor.log
fi
echo "-----------------------------------------" >> webserver/logs/monitor.log
echo "-----------------------------------------" >> webserver/logs/monitor.log
echo "-----------------------------------------" >> webserver/logs/monitor.log
echo "cronjobs-monitor started at `date`" >> webserver/logs/monitor.log
./csgoserver monitor >> webserver/logs/monitor.log
./csgoserver-2 monitor >> webserver/logs/monitor.log
./csgoserver-3 monitor >> webserver/logs/monitor.log
echo "cronjobs-monitor finished at `date`" >> webserver/logs/monitor.log
echo "-----------------------------------------" >> webserver/logs/monitor.log
echo "-----------------------------------------" >> webserver/logs/monitor.log
echo "-----------------------------------------" >> webserver/logs/monitor.log