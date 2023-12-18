# mongodb-replica-set

Goal:
- Expose a working Mongo-DB cluster on a Public IPs as a Replica Set, in order to can tolerate node failures
  - Configure the cluster with the minimun number of nodes in order to be able to tolerate just 1 node failure
- The Mongod-DB istances should contain a db called "test" with a sample document in a sample collection obtained by a Mongo-Restore of a previously prepared Mongo-Dump
  - Use the "--gzip" option
  - Perform the Mongo Dump & Restore command in the safest way possible (in order to ensure the data consistency) for this configuration
  
Expectations:
- Everything will done by code, no manual action will be considered in the review
- The Azure Cloud Resources will be created in the Resource Group: Giacomo-Quaglia-001
- Stack: Linux virtual machines with a Mongo-DB (No Containers) listening on the port 27017 port
- Data Disk: the Mongo-DB setup must rely on a dedicated and separate disk just for the Database data
- Mongo Version 4.4
- The Cloud Resources provisioning will be done ONLY through Terraform
  - The Azure credentials for Terraform are available in the LastPass shared folder "Shared-Tutoring Giacomo Quaglia"
- The Virtual Machines configurations will be performed through bash script/s to run after the Cloud Resources provisioning
  - The Terraform "remote-exec" provider or other solutions can be used to execute the script/s
    - In order to don't wast time, it's recommended to do not follow this approach for testing, but only as last step when everything is working
- The work, to be considered done, should be pushed in the git repository tutoring_giacomo-quaglia_terraform-001
  - branch name: "tickets/<current_ticket_id>"
  - in the root directory should be present:
    - the Terraform code
    - the Mongo-Dump
    - the Mongo-DB setup scripts
    - a file with the Mongo Dump command
    - a file with the Mongo Replica Set connection string to use
