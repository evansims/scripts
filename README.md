
# Scripts

## spideroak_backup.sh

A simple but effective tool for performing backups to the cloud using SpiderOak. The script can backup any arbitrary files or folders (so long as the account running the script has permissions; you may want to run this as a cron task under root for this reason), MySQL dumps and MongoDB exports. It compresses everything, optionally performs a git commit and push, and then sends the backup to your SpiderOak account for long term storage.

You can configure the script to store up to 7 or 30 days worth of these backups, or even an unlimited number of backups. With some minor modifications you could setup the script to support multiple backups per day (just change the stamp behavior to include time.)