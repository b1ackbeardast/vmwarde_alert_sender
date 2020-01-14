#!/bin/bash
LOG_FILE=$you_somepath
exec >>  $LOG_FILE
exec 2>> $LOG_FILE
set -ex
export GOVC_PASSWORD=$somepassword
export GOVC_URL=$vcenter_url
export GOVC_USERNAME=$vcenter_user
export GOVC_INSECURE=true
name=$somename
url='$alertmanager_url'

govc object.collect -json '$DC' triggeredAlarmState | jq '.[].Val.AlarmState[]? | [(.Entity.Type + ":" + .Entity.Value), ("Alarm:" + .Alarm.Value), .Time, .OverallStatus]|join(" ")' -r | while read l; do read h a t s <<<$l; object=$(govc object.collect -s $h name); alarm=$(govc object.collect -s $a info.name); echo $object,$alarm,$t,$s; done | grep -iv yellow |while IFS= read -r line

do
        curl -XPOST $url -d "[{ 
                \"status\": \"firing\",
                \"labels\": {
                        \"alertname\": \"$line\",
                        \"service\": \"VMware_alertmanager\",
                        \"severity\":\"warning\",
                        \"instance\": \"$vcenter_instance\"
                },
                \"annotations\": {
                        \"description\": \"$line\",
                        \"identifier\": \"$name\"
                },
                \"generatorURL\": \"http://prometheus.int.example.net/<generating_expression>\"
        }]"
done
