#!/bin/bash

auth5g_status=$(tail -n 1 /opt/auth5g.log | xargs)
laststatus=$(echo $auth5g_status | grep "key\|Success\|OTP")
error=$(echo $auth5g_status | grep "error")
if [ -z "$error" ]; then
    if [ "$laststatus" == "Success" ]; then
          authenticated=1
    else
          authenticated=0
    fi
else
     auth5g_status="Wrong key"
     authenticated=0
fi


echo $auth5g_status
if [ ! -z "$error" ] || [ ! -z "$laststatus" ]; then
      url={server_protocol}://{server_host}:{server_port}/status/safekey-report
      body_file='/opt/statusreport'
      uuid=$(grep 'uuid=' $body_file | cut -f2 -d '=' | cut -d ' ' -f1 | xargs)
      password=$(grep 'password=' $body_file | cut -f2 -d '=' | cut -d ' ' -f1 | xargs)
      org=$(grep 'organizationId=' $body_file | cut -f2 -d '=' | cut -d ' ' -f1 | xargs)

      postDataJson='{
                     "device": {
                        "uuid": "'$uuid'",
                        "password": "'$password'",
                        "organizationId": "'$org'"
                      }, "authenticated": '$authenticated', "remarks": "'$auth5g_status'" }'
      curl -k --interface {interface} -X POST "${url}" -H "Content-Type: application/json" -u "$apiuser:$apipassword" -d "${postDataJson}"
fi


