#!/bin/bash 

FILE=./out.csv

/bin/bash openshift_pod_check.sh
if test -f "$FILE"
then
    python3 send_emails.py
else
    echo "Email cannot be sent because the results file is not available!"
    exit 1
fi