#!/bin/sh
# Fetches a new OAuth 2.0 token from the Tesla API using email and password of
# a Tesla account.

CLIENT_ID=<Tesla App client ID here>
CLIENT_SECRET=<Tesla App client Secret here>
GRANT_TYPE=password

while getopts e:p: option
do
case "${option}"
in
e) EMAIL=${OPTARG};;
p) PASSWORD=${OPTARG};;
esac
done

if [ -z ${PASSWORD+x} ]; then
  read -p "Email: " EMAIL
  read -sp "Password: " PASSWORD
  echo
fi

curl -XPOST https://owner-api.teslamotors.com/oauth/token -d "password=$PASSWORD&email=$EMAIL&client_secret=$CLIENT_SECRET&client_id=$CLIENT_ID&grant_type=$GRANT_TYPE"
