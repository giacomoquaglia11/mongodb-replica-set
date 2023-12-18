username="mongouser"
password="mongopassword"
backup_path="/tmp/backup.gz"

echo "Initiate Replica Set"
(
  echo 'rs.initiate( { _id : "rs0", members: [ { _id: 0, host: "giacomo-quaglia-1.northeurope.cloudapp.azure.com:27017" }, { _id: 1, host: "giacomo-quaglia-2.northeurope.cloudapp.azure.com:27017" }, { _id: 2, host: "giacomo-quaglia-3.northeurope.cloudapp.azure.com:27017" } ]})' 
) | mongo

sleep 20s
echo "Mongo User Creation"
(
  echo 'use admin'
  echo "db.createUser( { user: \"$username\", pwd: \"$password\", roles: [ { role: \"root\", db: \"admin\" } ] } )"
) | mongo

echo "Mongo Restore"
mongorestore -u $username -p $password --authenticationDatabase admin --archive=$backup_path --gzip --oplogReplay