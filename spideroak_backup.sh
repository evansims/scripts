#!/bin/bash

#	Automated Cloud Backups to SpiderOak
#	-----
#	Feel free to use this in any environment and
#	modify it to your heart's content.
#	-----
#	Author: Evan Sims <hello@evansims.com>
#	Updates: https://github.com/evansims/scripts/

##### START OF CONFIGURATION ####

	# MySQL Database:
	mysqlUser=""
	mysqlPass=""

	# MongoDB Database:
	mongoUser=""
	mongoPass=""
	mongoHost=""

	# Backup target directory:
	backup="/home/username/backups/"

	# Backup these directories or files:
	folders[0]="/home/username/files/"
	folders[1]="/var/logs/"

	# If you're doing backups to a git repo and want to commit
	# these updates, enable this.
	gitCommit=0
	gitPushRepo="" # git push $gitPushRepo

	# 7 day backups are the default.
	# Your $backup directory will be filled with Monday, Tuesday, etc. folders.
	# Each weekday folder will be overwritten when the backup cycles around.
	stamp=$(date -u +%A)
	backupCurrent=$backup$stamp

	# OR uuncomment the following lines for ~30 day backups.
	# Your $backup directory will be filled with folders labled 01 through 31
	# representing each day of the month.
	#stamp=$(date -u +%d)
	#backup=$backup$stamp

	# OR uncomment the following lines for unlimited backups.
	# Your $backup directory will have a new folder created for each day
	# a backup is built. Keep an eye on space usage if you're going to use
	#this method.
	#stamp=$(date -u +%F)
	#backup=$backup$stamp

##### END OF CONFIGURATION ####

temp="$PWD/backup.tmp"
echo "Starting Backup..."

if [ ! -d "$backupCurrent" ]; then
        mkdir "$backupCurrent"
fi

if [ ! -d "$backupCurrent/mongodb" ]; then
        mkdir "$backupCurrent/mongodb"
fi

if [ ! -d "$backupCurrent/mysql" ]; then
        mkdir "$backupCurrent/mysql"
fi

if [ -z $mongoUser ] && [ -z $mongoPass ]; then
	echo "-----"
	echo -ne "Exporting MongoDB collections ... "
	mongodump -h $mongoHost -u $mongoUser -p $mongoPass -o "$backupCurrent/mongodb" 2>"$temp" >/dev/null
	tar -cjf "$backupCurrent/mongodb.tar.bz2" "$backupCurrent/mongodb/"* 2>"$temp"
	rm -R "$backupCurrent/mongodb/"*
	mv "$backupCurrent/mongodb.tar.bz2" "$backupCurrent/mongodb/mongodb.tar.bz2"
	echo "Done."
fi

if [ -z $mysqlUser ] && [ -z $mysqlPass ]; then
	echo "-----"
	echo -ne "Preparing to backup MySQL ... "
	databases=( $(mysql -u"$mysqlUser" -p"$mysqlPass" --skip-column-names --batch -e "show databases;" 2>"$temp") );
	echo "found ${#databases[@]} databases.";

	for i in ${databases[@]}; do
	        if [ $i != "information_schema" ] && [ $i != "mysql" ] && [ $i != "phpmyadmin" ]; then
	                echo -ne "Optimizing and backing up database $i ... "
	                mysql -u"$mysqlUser" -p"$mysqlPass" -D "$i" --skip-column-names --batch -e "optimize table $i" 2>"$temp" >/dev/null
	                mysqldump -u"$mysqlUser" -p"$mysqlPass" --opt $i | bzip2 -c > "$backupCurrent/mysql/$i.sql.bz2"
	                echo "Done."
	        fi
	done
fi

echo "-----"
for f in "${folders[@]}"
do
        if [ -d "$f" ]; then
                echo -ne "Backing up directory $f ... "
                d=$(basename $f)
                d="$d.tar.bz2"
        elif [ -f "$f" ]; then
                echo -ne "Backing up file $f ... "
                d=${f##*/}
                d="$d.tar.bz2"
        else
                echo "Error! $f could not be found."
                exit 1
        fi

        tar -cjf "$backupCurrent/$d" -C / ${f:1}
        echo "Done."
done

if [ ! -s $temp ]; then
        rm -f "$temp"
fi

if [ -z $gitCommit ]; then
	cd $backup
	echo "-----"
	echo "Committing changes to git ... "
	git add .
	git commit -m "Backup $stamp"

	if [ -z $gitPush ]; then
		git push $gitPush
	fi

	echo "Done."
fi

echo "-----"
echo -ne "Pushing data to SpiderOak ... "

SpiderOak --empty-garbage-bin 2>"$temp" >/dev/null
SpiderOak --batchmode 2>"$temp" >/dev/null
SpiderOak --purge-historical-versions all 2>"$temp" >/dev/null
SpiderOak --vacuum 2>"$temp" >/dev/null

echo "Done."

echo "-----"
echo "Backup Complete!"

exit 0