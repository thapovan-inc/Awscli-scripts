#!/bin/bash

echo "please Enter project name"
read pname
clear

security_group_region="ap-south-1"

port_ids="80 22 3306"
# define groups
r1=$pname-rds-envirinment

echo "creating rds-database"
#RDS Database
g_id_dev_rds=`aws ec2 create-security-group --group-name $r1 --description "security group for $r1 development environment in EC2" | grep sg | cut -d '"' -f4`
aws ec2 create-tags --resources $g_id_dev_rds --tags Key=Name,Value=$r1
echo "creating qa-rds"


echo "security groups created \n Authorisation in progress ..."
 myip=$(curl -s https://api.ipify.org);


 for port in $port_ids

 do

 aws ec2 authorize-security-group-ingress -group-name $r1 --protocol tcp --port $port --cidr ${myip}/32 --region "$security_group_region"

 aws ec2 authorize-security-group-ingress -group-name $r2 --protocol tcp --port $port --cidr ${myip}/32 --region "$security_group_region"
aws ec2 authorize-security-group-ingress --group-name $r3 --protocol tcp -port $port --cidr ${myip}/32 --region "$security_group_region"


echo "RDS MY ip added in rds security group environment ...."
clear

echo "Creating Dev RDS"

aws rds create-db-instance --db-instance-identifier $pname-Dev --allocated-storage 10 --db-instance-class db.t2.micro --engine mysql --master-username $pname --master-user-password $pname-456$%^ --no-multi-az --auto-minor-version-upgrade --vpc-security-group $g_id_dev_rds --storage-type gp2 --tags '{"Key": "Name","Value": "rds-dev"}'

echo "Done with RDS Mysql database Creation"

echo '{' >> ~/$pname-creds.json
echo '{' >> ~/$pname-creds.json
echo '"RDS UserName"' ':' '"' "$pname" '"' >> ~/$pname-creds.json
echo '"RDS Password" :' '"' "$pname-456$%^" '"' >> ~/$pname-creds.json

echo "Waiting 333 seconds ..."

for ((i=333;i>=1;i--))
do
	echo "							$i \n"
	sleep 1
done

rds_db_endp=`aws rds describe-db-instances |grep -i address | grep dev| cut -d '"' -f4`

echo '"rds-dev Endpoint"' ':''"' "$rds_db_endp"'"' >> ~/$pname-creds.json
echo '}' >> ~/$pname-creds.json
