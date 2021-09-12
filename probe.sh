#!/bin/sh

API_BASE_URL=https://owner-api.teslamotors.com

while getopts p:m:t:d: option
do
case "${option}"
in
p) API_PATH=${OPTARG};;
m) METHOD=${OPTARG};;
t) TOKEN=${OPTARG};;
d) DATA=${OPTARG};;
esac
done

REQUEST_URL=$API_BASE_URL/$API_PATH

if [ -z ${METHOD+x} ]; then
  echo "Default to GET"
  METHOD=GET
fi

if [ -z ${TOKEN+x} ]; then
  echo "No access token set"
else
  echo "TOKEN is set ${TOKEN}"
  AUTH_HEADER="Authorization: bearer $TOKEN"
fi

if [ -z ${DATA+x} ]; then
  echo "No data to send"
else
  echo "Data to send: $DATA"
  PARAMS+=(-d "$DATA")
fi

PARAMS=()
PARAMS+=(-i)
PARAMS+=(-v)
PARAMS+=(-X "$METHOD")
PARAMS+=(-H "$AUTH_HEADER")
#PARAMS+=(-H "Content-Type: application/json")

PARAMS+=("$REQUEST_URL")
curl "${PARAMS[@]}"
