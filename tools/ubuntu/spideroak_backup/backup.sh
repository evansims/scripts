#!/bin/bash

# ---------------------------------------------------------
# Automated Cloud Backups to SpiderOak
# ---------------------------------------------------------
# Written by Evan Sims <hello@evansims.com>
#
# Latest version always available from:
#   https://github.com/evansims/scripts/
# ---------------------------------------------------------

##### START OF CONFIGURATION ####

  # Backup target directory:
  backup="/home/username/backups/"

  stamp=$(date -u +%A) # Keep backups for the last 7 days.
  #stamp=$(date -u +%d) # OR uncomment this line for ~30 day backups.
  #stamp=$(date -u +%F) # OR uncomment this line for infinite backups.

  # Backup these directories or files:
  folders[0]="/home/username/files/"
  folders[1]="/var/logs/"

  # MySQL backup. Leave these values empty if you don't use it.
  mysqlUser=""
  mysqlPass=""

  # MongoDB backup. Leave these values empty if you don't use it.
  mongoUser=""
  mongoPass=""
  mongoHost=""

  # If your backup target is also a git repo you can automatically commit and push changes to a remote, if desired.
  # Leave empty to do disable.
  gitPush="" # git push $gitPush

##### END OF CONFIGURATION ####

backupCurrent=$backup$stamp
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
        echo -ne "Backing up database $i ... "
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

if [ -z $gitPush ]; then
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

SpiderOak --include-dir="$backup" 2> "$temp" >/dev/null
SpiderOak --empty-garbage-bin 2>"$temp" >/dev/null
SpiderOak --batchmode 2>"$temp" >/dev/null
SpiderOak --purge-historical-versions all 2>"$temp" >/dev/null
SpiderOak --vacuum 2>"$temp" >/dev/null

echo "Done."

echo "-----"
echo "Backup Complete!"

exit 0