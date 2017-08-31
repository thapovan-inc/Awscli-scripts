#!/bin/bash
# Shell Script to Update AWS EC2 Security Groups
# Note that existing IP rules will be deleted

# CONFIG - Only edit the below lines to setup the script
# ===============================

# AWS Profile Name
profile="default"

# Groups, separated with spaces
group_ids="defaultgroup1 defaultgroup2"

# Fixed IPs, separated with spaces
fixed_ips="172.1.1.16/32 172.1.1.18/32 ";

# Port
port=80;

# ===============================

die() { echo "$@" 1>&2 ; exit 1; }



# Loop through groups
for group_id in $group_ids
do

    # Display group name
    echo -e "\033[34m\nModifying Group: ${group_id}\033[0m";

    # Get existing IP rules for group
    ipv4=$(aws ec2 --profile=$profile describe-security-groups --filters Name=ip-permission.to-port,Values=$port Name=ip-permission.from-port,Values=$port Name=ip-permission.protocol,Values=tcp --group-ids $group_id --output text --query 'SecurityGroups[*].{IP:IpPermissions[?ToPort==`'$port'`].IpRanges}' | sed 's/IP	//g');

 ipv6=$(aws ec2 --profile=$profile describe-security-groups --filters Name=ip-permission.to-port,Values=$port Name=ip-permission.from-port,Values=$port Name=ip-permission.protocol,Values=tcp --group-ids $group_id --output text --query 'SecurityGroups[*].{IP:IpPermissions[?ToPort==`'$port'`].Ipv6Ranges}' | sed 's/IP	//g');


    # Loop through IPs
    for ip in $ipv4
    do
        echo -e "\033[31mRemoving IP: $ip\033[0m"

        # Delete IP rules matching port
        aws ec2 revoke-security-group-ingress --profile=$profile --group-id $group_id --protocol tcp --port $port --cidr $ip
    done

    for ip in $ipv6
    do
        echo -e "\033[31mRemoving IPv6: $ip\033[0m"

        # Delete IP rules matching port
       aws ec2 revoke-security-group-ingress --profile=$profile --group-id $group_id --ip-permissions '[{"IpProtocol": "tcp",
 "FromPort":'$port', "ToPort": '$port', "Ipv6Ranges": [{"CidrIpv6": "'$ip'"}]}]'
    
    done

    # Get current public IP address
    #myip=$(curl -s https://api.ipify.org);

    #echo -e "\033[32mSetting Current IP: ${myip}\033[0m"

    # Add current IP as new rule
    #aws ec2 authorize-security-group-ingress --profile=$profile --protocol tcp --port $port --cidr ${myip}/32 --group-id $group_id
	find  -type f -name "ips*" -exec rm -f {} \;
	wget https://www.cloudflare.com/ips-v4
	
	while read p;
	 do aws ec2 authorize-security-group-ingress --group-id $group_id --protocol tcp --port 80 --cidr $p; done< ips-v4
	wget https://www.cloudflare.com/ips-v6

	while read p; do echo $p;
	aws ec2 authorize-security-group-ingress --group-id $group_id   --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 80, "ToPort": 80, "Ipv6Ranges": [{"CidrIpv6": "'$p'"}]}]';
	done< ips-v6



    # Loop through for fixed IPs
    for ip in $fixed_ips
    do
        #echo -e "\033[32mSetting Fixed IP: ${ip}\033[0m"
	echo $ip;

        # Add fixed IP rules
        aws ec2 authorize-security-group-ingress --profile=$profile --protocol tcp --port $port --cidr ${ip} --group-id $group_id
	done

	done
