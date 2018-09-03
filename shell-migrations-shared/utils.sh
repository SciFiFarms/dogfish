#!/bin/bash

reboot_function()
{
    until vernemq ping
    do
        sleep 1
    done
    
    sleep 2 && vernemq stop &
}

# $1: The field to extract. 
# $2: The JSON string.
extract_from_json(){
    grep -Eo '"'$1'":.*?[^\\]"' <<< "$2" | cut -d \" -f 4
}

# $1: The secret name (Without stack reference, this will be delt with on portainer's end.)
# $2: The secret itself
function create_secret()
{
    mosquitto_pub -h mqtt -p 8883 -q 1 \
        -t portainer/secrets/create/$1 \
        -m "$2" \
        -u $(cat /run/secrets/mqtt_username) \
        -P "$(cat /run/secrets/mqtt_password)" \
        --cafile /run/secrets/ca 
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