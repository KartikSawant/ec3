#!/bin/bash

# Set default AWS profile (uncomment and set your profile if needed)
# export AWS_PROFILE=<aws-profile>

# Function to list all instances
list_instances() {
    echo "Available instances:"
    cat "$map_file" | while read -r line; do
        instance_alias=$(echo "$line" | cut -d '=' -f1)
        instance_info=$(echo "$line" | cut -d '=' -f2)
        instance_id=$(echo "$instance_info" | cut -d ':' -f1)
        region=$(echo "$instance_info" | cut -d ':' -f2)
        ssh_host=$(echo "$instance_info" | cut -d ':' -f3-)
        echo "Alias: $instance_alias, Instance ID: $instance_id, Region: $region, SSH Host: ${ssh_host:-N/A}"
    done
}

# Function to get instance info
get_instance_info() {
    instance_info=$(grep -w "^$alias" "$map_file" | cut -d '=' -f2)
    instance_id=$(echo "$instance_info" | cut -d ':' -f1)
    region=$(echo "$instance_info" | cut -d ':' -f2)
    ssh_alias=$(echo "$instance_info" | cut -d ':' -f3-)
}

# Function to get public IP
get_public_ip() {
    public_ip=$(aws ec2 describe-instances --instance-ids "$instance_id" --region "$region" \
                --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
}

# Function to check instance state
check_instance_state() {
    instance_state=$(aws ec2 describe-instances --instance-ids "$instance_id" --region "$region" \
                      --query "Reservations[*].Instances[*].State.Name" --output text)
    if [ "$instance_state" == "running" ]; then
        get_public_ip
    fi
}

# Function to stop instance
stop_instance() {
    if [ "$instance_state" == "stopped" ]; then
        echo "Instance with ID '$instance_id' in region '$region' is already stopped."
        exit 0
    elif [ "$instance_state" != "running" ]; then
        echo "Instance with ID '$instance_id' in region '$region' is not in a running state (current state: $instance_state)."
        exit 1
    fi

    aws ec2 stop-instances --instance-ids "$instance_id" --region "$region" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "Instance with ID '$instance_id' in region '$region' is stopping..."
    else
        echo "Failed to stop instance with ID '$instance_id' in region '$region'."
    fi
}

# Function to start instance
start_instance() {
    if [ "$instance_state" == "running" ]; then
        echo "Instance with ID '$instance_id' in region '$region' is already running."
        exit 0
    elif [ "$instance_state" != "stopped" ]; then
        echo "Instance with ID '$instance_id' in region '$region' is not in a stopped state (current state: $instance_state)."
        exit 1
    fi

    aws ec2 start-instances --instance-ids "$instance_id" --region "$region" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "Instance with ID '$instance_id' in region '$region' is starting...Please wait for the IP Address"
        aws ec2 wait instance-running --instance-ids "$instance_id" --region "$region"
        get_public_ip
        echo "Instance with ID '$instance_id' in region '$region' is now running with public IP: $public_ip"
        [ "$update_flag" = true ] && update_ssh_config
    else
        echo "Failed to start instance with ID '$instance_id' in region '$region'."
    fi
}

# Function to update SSH config
update_ssh_config() {
    if [ -z "$ssh_alias" ]; then
        echo "No SSH alias provided for '$alias'; skipping SSH config update."
        return
    fi

    echo "Updating SSH config for Host '$ssh_alias' with IP '$public_ip'"

    tmp_file=$(mktemp)

    awk -v host="$ssh_alias" -v ip="$public_ip" '
    BEGIN { found=0 }
    $1 == "Host" && $2 == host { found=1; print; next }
    found == 1 && $1 == "HostName" { print "  HostName " ip; found=0; next }
    { print }
    ' "$ssh_config" > "$tmp_file" && mv "$tmp_file" "$ssh_config"

    echo "SSH config updated: ssh $ssh_alias"
}

# Main script execution

if [ -z "$1" ]; then
    echo "Usage: $0 <start|stop|list|status> [alias]"
    exit 1
fi

action="$1"
alias="$2"
update_flag=false

if [[ "$3" == "--update" ]]; then
  update_flag=true
fi

map_file="$HOME/.ec3rc"
ssh_config="$HOME/.ssh/config"

if [ ! -f "$map_file" ]; then
    echo "Mapping file '$map_file' not found."
    exit 1
fi

if [ "$action" == "list" ]; then
    list_instances
    exit 0
fi

if [ -z "$alias" ]; then
    echo "Usage: $0 <start|stop|list|status> [alias]"
    exit 1
fi

get_instance_info

if [ -z "$instance_id" ] || [ -z "$region" ]; then
    echo "No instance or region found for alias '$alias'."
    exit 1
fi

echo "Instance ID: $instance_id"
echo "Region: $region"

check_instance_state

if [ "$action" == "status" ]; then
    echo "Instance with ID '$instance_id' in region '$region' is in state: $instance_state."
    if [ "$instance_state" == "running" ]; then
        echo "Public IP: $public_ip"
    fi
    exit 0
fi

if [ "$action" == "stop" ]; then
    stop_instance
    exit 0
fi

if [ "$action" == "start" ]; then
    start_instance
    exit 0
fi

