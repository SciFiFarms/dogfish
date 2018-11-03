#!/bin/bash

reboot_function()
{
    kill -s SIGTERM 1
}

# $1: The field to extract. 
# $2: The JSON string.
extract_from_json(){
    grep -Eo '"'$1'":.*?[^\\]"' <<< "$2" | cut -d \" -f 4
}

# $1: The mount point(Without stack reference, this will be delt with on portainer's end.)
#   Should be of the format service_name/mount_point
#   If the swarm service is different than the service name used to save the 
#   secret, then use secret_service_name&swarm_service_name. For example:
#   portainer/secret/create/node-red&nr/mqtt_username
# $2: The secret itself
function create_secret()
{
    #echo "Starting create_secret()"
    until mosquitto_pub -i dogfish_create_secret -h mqtt -p 8883 -q 2 \
        -t portainer/secret/create/$1 \
        -m "$2" \
        -u $(cat /run/secrets/mqtt_username) \
        -P "$(cat /run/secrets/mqtt_password)" \
       --cafile /run/secrets/ca
    do
        echo "Couldn't connect to MQTT. Sleeping."
        sleep 5
    done
        
    #echo "Finished create_secret()"
}

# $1: The number of random characters to generate.
function get_random()
{
    local response
    # TODO: I think there is a programatic way to do this that would allow for 
    # max retries annd sleep time to be passed in as parameters. 
    until response=$(http --check-status --verify=/run/secrets/ca \
        POST https://vault:8200/v1/sys/tools/random/$1 \
        X-Vault-Token:$(cat /run/secrets/token))
    do
        echo "Can't reach Vault, sleeping." >&2
        sleep 1
    done;
    echo $response
}