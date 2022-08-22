#!/bin/bash

echo "INFO: Starting IP Alert Setup"

shopt -s lastpipe 
shopt -so pipefail

jq --version >/dev/null 2>&1
jq_ok=$?

[[ "$jq_ok" -eq 127 ]] && \
    echo "ERROR: jq not installed" && exit 2
[[ "$jq_ok" -ne 0 ]] && \
    echo "ERROR: unknown error in jq" && exit 2

curl --version >/dev/null 2>&1
curl_ok=$?

[[ "$curl_ok" -eq 127 ]] && \
    echo "fatal: curl not installed" && exit 2

while true; do
    read -p "Enter webhook: " webhook
    # check webhook includes "https://discord.com/api/webhooks/"
    if [[ $webhook == *"discord.com/api/webhooks/"* ]]; then
        break
    elif [ -n "$webhook" ]; then
        echo "ERROR: Invalid webhook URL"
    else
        echo "ERROR: Webhook is required"
    fi
done
while true; do
    read -p "Enter server name: " server_name
    if [ -n "$server_name" ]; then
        break
    fi
    echo "ERROR: Server name is required"
done
read -p "Enter title (Default: Ip Check): " title
if [ -z "$title" ]; then
    title="Ip Check"
fi

while true; do
    read -p "Is private ip? [Y/N] (Default: N): " private_ip
    if [ -z "$private_ip" ]; then
        description=$(curl https://ip.ontdb.com/)
        break
    elif "$private_ip" == "Y" || "$private_ip" == "y"; then
        description=$(hostname -I)
        break
    elif "$private_ip" == "N" || "$private_ip" == "n"; then
        description=$(curl https://ip.ontdb.com/)
        break
    else
        echo "ERROR: Please enter Y or N"
    fi
done

mkdir -p /opt/ipalert

echo "===========[CONFIG]==========="
echo "Webhook: $webhook"
echo "Server name: $server_name"
echo "Title: $title"
echo "Description: $description (Automatically generated)"
echo "==================================="

while true; do
    read -p "Is this correct? [Y/N] (Default: Y): " correct
    if [ -z "$correct" ]; then
        break
    elif "$correct" == "Y" || "$correct" == "y"; then
        break
    elif "$correct" == "N" || "$correct" == "n"; then
        echo "ERROR: Please try again"
        exit 1
    else
        echo "ERROR: Please enter Y or N"
    fi
done

echo "INFO: Starting download discord.sh"
curl -L -o /opt/ipalert/discord.sh https://raw.githubusercontent.com/ChaoticWeg/discord.sh/v1.6.1/discord.sh > /dev/null 2>&1
chmod +x /opt/ipalert/discord.sh
echo "INFO: Downloaded to /opt/ipalert/discord.sh"
echo "INFO: Generating send command"
echo "/opt/ipalert/discord.sh --webhook-url=$webhook --username $server_name --title $title --description $description --timestamp" > /opt/ipalert/run.sh
chmod +x /opt/ipalert/run.sh
echo "INFO: Generated send command to /opt/ipalert/run.sh"
echo "INFO: Adding crontab entry"
echo "*0 * * * * root /opt/ipalert/run.sh" >> /etc/crontab
echo "INFO: Added crontab entry"
echo "INFO: IP Alert Setup Done!"
echo "INFO: If contab entry is not working, please run the following command:"
echo "INFO:       crontab -e"
echo "INFO: And add the following line:"
echo "INFO:       0 * * * * /opt/ipalert/run.sh"
echo "INFO: Then save and exit (:wq)"
echo "INFO: If you want to change the webhook, please run this script again."
echo ""
exit 0