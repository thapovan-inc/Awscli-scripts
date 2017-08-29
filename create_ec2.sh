#!/bin/bash

#172.31.0.0/16

profile="default"

port_ids="80 22 3306"
security_group_name="newaws"
security_group_description=" new security group is created and attached to vpc"
security_group_region="ap-south-1"

echo "create vpc"

vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)

echo -e "\033[34m\n vpc id: ${vpc_id}\033[0m"
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $vpc_id --enable-dns-hostnames "{\"Value\":true}"

echo "Adding Internet gateway"

internetGatewayId=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)

 aws ec2 attach-internet-gateway --internet-gateway-id $internetGatewayId --vpc-id $vpc_id

echo "Creating subnet" 

subnetId=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.0.0/28 --query 'Subnet.SubnetId' --output text)


echo "Creating route table"

routeTableId=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text)

aws ec2 associate-route-table --route-table-id $routeTableId --subnet-id $subnetId

aws ec2 create-route --route-table-id $routeTableId --destination-cidr-block 0.0.0.0/0 --gateway-id $internetGatewayId

echo $routeTableId

echo -e "\033[34m\n route table: ${routeTableId}\033[0m"

echo -e "security_group_name: ${security_group_name}\033[0m"

securityGroupId=$(aws ec2 create-security-group --group-name ${security_group_name} --description "${security_group_description}" --vpc-id $vpc_id --query 'GroupId' --output text)

 myip=$(curl -s https://api.ipify.org);
 
echo $securityGroupId

for port in $port_ids

 do
	 aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port $port --cidr ${myip}/32 --region "$security_group_region"

	for ip in $FIXED_IPS
do
	 echo $port
	 echo $ip
echo $myip
 aws ec2 authorize-security-group-ingress --group-id $securityGroupId --protocol tcp --port $port --cidr $ip --region  "$security_group_region"

	done


done 


aws ec2 create-key-pair --key-name thapovannew-key --query 'KeyMaterial' --output text > ~/.ssh/yourkey.pem

chmod 400 ~/.ssh/thapovannew-key.pem

instanceId=$(aws ec2 run-instances --image-id ami-df413bb0 --count 1 --instance-type t2.micro --key-name thapovannew-key --security-group-ids $securityGroupId --subnet-id $subnetId --associate-public-ip-address --query 'Instances[0].InstanceId' --output text)

echo $instanceId

instanceUrl=$(aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[0].Instances[0].PublicDnsName' --output text)
echo $instanceUrl


# IF want to connect the created instance  use below syntax
echo "Host ${instanceUrl}\n    StrictHostKeyChecking no\n" >> ~/.ssh/config;
chmod 400 ~/.ssh/config;

ssh -i ~/.ssh/yourkey.pem ubuntu@$instanceUrl











