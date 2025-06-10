#!/bin/bash

function getList {
        access=$1
        otp_file=/opt/safelogin/otp.dat
        keys_file=/opt/safelogin/keys.dat
        key_file_encrypted=/opt/safelogin/keys.dat.gpg
        overview_url=$host/api-local/Device/StatusOverView
        response=$(curl -k -s -b cookies.txt -X GET "${overview_url}" -H "Content-Type: application/json" -H "Authorization: Bearer "$access)
        echo $response | jq -c '. | {"totalItems", "devices": [.data[] | {"uuid": "\(.uuid)", "deviceName": "\(.deviceName)", "status": "\(.status)", "lastTimeSeen": "\(.lastTimeSeen)"}]}'

        echo "Enter uuid of device you want to reboot:"
        read deviceuuid
        echo "Triggering reboot device remote command..."
        remotecommand_url=$host/api-local/Device/RemoteCommand/
        onetimekey=$(cat $otp_file)
        deviceuuid=$(echo $deviceuuid | xargs)
        postDataJsonRemote='{"deviceId":"'$deviceuuid'","command":214,"remarks":"i46-'$onetimekey','$safekey_uuid'"}'
        responseRemote=$(curl -k -s -b cookies.txt -X POST "${remotecommand_url}" -H "Content-Type: application/json" -d "${postDataJsonRemote}" -H "Authorization: Bearer "$access)
        responsejq=$(echo $responseRemote | jq -r '.safekey')

        if [ "$responsejq" == "null" ]; then
          echo "Error while retrieving response"
        else
          responseKey=$(echo $responsejq | jq -r '.responseKey')
          storageKey=$(echo $responsejq | jq -r '.storageKey')
          encryptionKey=$(echo $responsejq | jq -r '.encryptionKey')
          export GPG_TTY=$(tty) && echo $storageKey | sudo gpg --batch --yes --passphrase-fd 0 --output $keys_file -d $key_file_encrypted
          echo $(sudo head -n 1 $keys_file) | sudo tee $otp_file >> /dev/null
          sudo sed -i '1d' $keys_file
          echo $encryptionKey | sudo gpg --batch --yes --passphrase-fd 0 --symmetric $keys_file
          echo "The device you selected will reboot after a few minutes."
          echo
          getList $access
        fi
}

function getLogin {
  other=$1
  if [ "$other" == "n" ] || [ "$other" == "N" ]; then
     echo "Enter your i46 email: "
     read email

     regex="^[a-z0-9!#\$%&'*+/=?^_\`{|}~-]+(\.[a-z0-9!#$%&'*+/=?^_\`{|}~-]+)*@([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?\$"

     if [[ $email =~ $regex ]] ; then
         echo "Enter your password: "
         read -s PASSWORD
         echo "Logging in..."
         url=$host/api-local/Account/login/
         postDataJson='{"email": "'$email'", "password": "'$PASSWORD'" }'
         login=$(curl -k -s -c cookies.txt -X POST "${url}" -H "Content-Type: application/json" -u "$apiuser:$apipassword" -d "${postDataJson}")
         access=$(echo $login | jq -r '.access')
     else
         echo "Invalid email"
         exit 1
     fi
  else

    if [ "$other" == "y" ] || [ "$other" == "Y" ]; then
      echo "Logging in..."
      access=$(cat $token_file | cut -d, -f2)
    else
      echo "Enter y or n"
      read answer
      getLogin $answer
    fi
  fi

}

function main {
  datetime=$(date +'%F %T')
  ip=$(ip -o route get to 8.8.8.8 | sed -n 's/.*src \([0-9.]\+\).*/\1/p')
  host={server_protocol}://{server_host}:{server_port}
  safekey_uuid={device_uuid}

  token_file=/opt/safelogin/token.dat
  audit_file=/opt/safelogin/audit.csv

  if [ -f $token_file ]; then
    if [[ $(find "$token_file" -mtime +1 -print) ]]; then
      echo "File $token_file exists and is older than 1 day. Deleting token..."
    fi
  fi

  if [ -f $token_file ]; then
     email=$(cat $token_file | cut -d, -f1)
    echo "Logging in as" $email

    echo
    echo "Do you want to continue with the current user? [y/n]"
    read other
    getLogin $other
  else
     echo "Enter your i46 email: "
     read email
     echo "Enter your password: "
     read -s PASSWORD
     echo "Logging in..."
     url=$host/api-local/Account/login/
     postDataJson='{"email": "'$email'", "password": "'$PASSWORD'" }'
     login=$(curl -k -s -c cookies.txt -X POST "${url}" -H "Content-Type: application/json" -u "$apiuser:$apipassword" -d "${postDataJson}")
     access=$(echo $login | jq -r '.access')
  fi

  if [ $access == "null" ]; then
    echo "Login failed. Email or password is incorrect."
    status=fail
    echo $datetime","$ip","$email",UserLogin,"$status | sudo tee -a $audit_file
    if [ -f $token_file ]; then
      sudo rm $token_file
    fi
  else
    echo $email","$access | sudo tee $token_file
    echo "Running SafeKey..."
    safekey_check=$(ls /opt/safelogin/safekey)
    if [ ! -z "$safekey_check" ]; then
     /opt/safelogin/safekey | sudo tee -a /opt/safelogin/safelogin.log >/dev/null


          safekey_status=$(tail -n 1 /opt/safelogin/safelogin.log | xargs)
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
                url=$host/status/safelogin-report
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



     safekey_status2=$(tail -n 1 /opt/safelogin/safelogin.log | xargs | cut -f 1 -d " ")
     if [ -z "$safekey_status2" ]; then
               echo "SafeLogin failed"
               status=fail
               echo $datetime","$ip","$email",UserLogin,"$status | sudo tee -a $audit_file
               if [ -f $token_file ]; then
                sudo rm $token_file
               fi

               echo
               getLogin "n"
     fi
     if [ $safekey_status2 == "Success" ]; then
        echo "Login successful!"
        echo "Retrieving data..."
        status=success
        echo $datetime","$ip","$email",UserLogin,"$status | sudo tee -a $audit_file
        getList $access
     else
        echo "SafeLogin failed"

        status=fail
        echo $datetime","$ip","$email",UserLogin,"$status | sudo tee -a $audit_file
        if [ -f $token_file ]; then
         sudo rm $token_file
        fi

        echo
        getLogin "n"
     fi
    fi
  fi
  #date,ip_address,user_name,operation,status

}
main "$@"