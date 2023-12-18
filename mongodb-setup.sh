disk_block_name="sdc"
data_folder="/mongodata"
backup_path="/tmp/backup.gz"
keyfile_tmp="/tmp/mongodb-keyfile"
keyfile="/mongodata/mongodb-keyfile"

echo "Formatting Disk"
mkfs.xfs "/dev/$disk_block_name"
sleep 5

echo "Disk Mount"
mkdir $data_folder
mount "/dev/$disk_block_name" $data_folder

echo "/etc/fstab configuration to make the mount persistent"
disk_uuid=$(blkid | grep -i $disk_block_name | awk -F'UUID="' '{print $2}' | awk -F'"' '{print $1}')
echo "UUID=$disk_uuid $data_folder xfs defaults,nofail 0 2" >> /etc/fstab

echo "Mongo DB Install"
apt-get update
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
apt-get update
apt-get install -y mongodb-org

echo "Mongodb-keyfile"
cp $keyfile_tmp $data_folder
chmod 400 $keyfile
chown mongodb:mongodb $keyfile

echo "Mongo Configuration"
cp /etc/mongod.conf /etc/mongod.conf_old
echo -n "
storage:
  dbPath: $data_folder
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

processManagement:
  timeZoneInfo: /usr/share/zoneinfo 

security:
  keyFile: $keyfile

replication:
  replSetName: "rs0" " > /etc/mongod.conf
chown -R mongodb:mongodb $data_folder
sleep 5s

echo "Mongo Restart"
systemctl stop mongod
sleep 20s
systemctl start mongod
sleep 20s
