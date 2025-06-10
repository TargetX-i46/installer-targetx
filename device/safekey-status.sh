#!/bin/bash

safekey_status=$(tail -n 1 /opt/safekey.log | xargs)
laststatus=$(echo $safekey_status | grep "key\|Success\|OTP")
error=$(echo $safekey_status | grep "error")
if [ -z "$error" ]; then
    if [ "$laststatus" == "Success" ]; then
          authenticated=1
    else
          authenticated=0
    fi
else
     safekey_status="Wrong key"
     authenticated=0
fi


echo $safekey_status
if [ ! -z "$error" ] || [ ! -z "$laststatus" ]; then
      url={server_protocol}://{server_host}:{server_port}/status/cloud-report
      body_file='/opt/statusreport'
      uuid=$(grep 'uuid=' $body_file | cut -f2 -d '=' | cut -d ' ' -f1 | xargs)
      password=$(grep 'password=' $body_file | cut -f2 -d '=' | cut -d ' ' -f1 | xargs)
      org=$(grep 'organizationId=' $body_file | cut -f2 -d '=' | cut -d ' ' -f1 | xargs)

      postDataJson='{
                     "device": {
                        "uuid": "'$uuid'",
                        "password": "'$password'",
                        "organizationId": "'$org'"
                      }, "authenticated": '$authenticated', "remarks": "'$safekey_status'" }'
      curl -k -X POST "${url}" -H "Content-Type: application/json" -u "$apiuser:$apipassword" -d "${postDataJson}"
fi


