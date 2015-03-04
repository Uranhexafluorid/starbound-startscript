#!/bin/sh

# starbound startscript
#Serververzeichnis
dir=/home/steam/starbound

PIDFILE=/home/steam/starbound/starbound.pid

#backupverzeichnis
backup=/home/steam/backup/

#speicherdauer der backups in tagen
days=21

#########################################

#aktuelles datum
date=$(date +%F-%H-%M)

cd $dir

do_start() {
	cd $dir/linux64
	screen -LdmS starbound ./starbound_server
	sleep 10
	netstat -tlpn | grep 21025 | sed -n -e '1p' | awk '{ print $7 }' | cut -d'/' -f1 | grep -E '[[:digit:]]' > $PIDFILE
	echo "Starbound-Server wurde gestartet, PID "$(cat $PIDFILE)
}

do_stop() {
	kill -15 $(cat $PIDFILE)
	echo "Starbound-Server wurde gestoppt, PID "$(cat $PIDFILE)
	rm -f $PIDFILE
}

do_restart() {
	do_stop
	sleep 60
	do_start
}

do_backup() {
	cp -r $dir/giraffe_storage/universe $dir/temp/
	tar -czf $backup/starbound_$date.tar.gz $dir/temp/
	rm $backup/starbound_lastbackup.txt
	touch $backup/starbound_lastbackup.txt
	echo $date > $backup/starbound_lastbackup.txt
	rm -rf $dir/temp/
}

do_clean() {
	cd $backup
	ls -t1 | tail -n +$days | xargs rm
	cd $dir
	rm $dir/linux64/screenlog.0
	touch $dir/linux64/screenlog.0
}

do_check() {
JOINED=$(grep -o "Logged in account  as player" $dir/linux64/screenlog.0 | sed '2,999d')
if [ "$JOINED" = "Logged in account  as player" ] ;
	then
		do_backup
		do_clean
fi

LEFT=$(grep -o "disconnected" $dir/linux64/screenlog.0 | sed '2,999d')
if [ "$LEFT" = "disconnected" ] ;
	then
		do_backup
		do_clean
fi
}

case "$1" in
        start)
			do_start
        ;;
        restart)
			do_restart
        ;;
        stop)
			do_stop
        ;;
        backup)
			do_check
        ;;
        *)
			echo "Usage: /etc/init.d/minecraft {start|stop|restart|backup}"
			exit 1
        ;;
esac