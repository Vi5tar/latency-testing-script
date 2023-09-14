#!/bin/bash

# Initialize variables with default values
url=""
accessToken=""
sheetId=""
range="Sheet1"

# Loop through the provided arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --url)
            url="$2"
            shift # Consume the argument value
            ;;
        --accessToken)
            accessToken="$2"
            shift # Consume the argument value
            ;;
        --sheetId)
            sheetId="$2"
            shift # Consume the argument value
            ;;
        --range)
            range="$2"
            shift # Consume the argument value
            ;;
        *)
            # Unknown argument
            echo "Unknown argument: $1"
            exit 1
            ;;
    esac
    shift # Consume the argument name
done

# Check if the URL argument is provided
if [ -z "$url" ]; then
    echo "Usage: $0 --url <url> [--accessToken <accessToken>] [--sheetId <sheetId>] [--range <range>]"
    exit 1
fi

ipInfo=$(curl ipinfo.io)
echo "$ipInfo"

# Define the format as a multi-line string
format='{
  "response_code": %{response_code},
  "time_namelookup": %{time_namelookup},
  "time_connect": %{time_connect},
  "time_appconnect": %{time_appconnect},
  "time_pretransfer": %{time_pretransfer},
  "time_redirect": %{time_redirect},
  "time_starttransfer": %{time_starttransfer},
  "time_total": %{time_total}
}'

# Use the format in the Curl command
curlTime=$(curl -w "$format" -o /dev/null -s $url)
echo "$curlTime"

if [ -z "$accessToken" ]; then
    echo "No access token provided. Skipping write to Google Sheet."
    exit 0
fi

if [ -z "$sheetId" ]; then
    echo "No sheet ID provided. Skipping write to Google Sheet."
    exit 0
fi

curl --request POST \
  "https://sheets.googleapis.com/v4/spreadsheets/$sheetId/values/$range:append?valueInputOption=RAW" \
  --header "Authorization: Bearer $accessToken" \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --data "{\"values\":[[\"$url\", \"$(echo $curlTime | jq -r .response_code)\", \"$(echo $ipInfo | jq -r .ip)\", \"$(echo $ipInfo | jq -r .hostname)\", \"$(echo $ipInfo | jq -r .city)\", \"$(echo $ipInfo | jq -r .region)\", \"$(echo $ipInfo | jq -r .country)\", \"$(echo $ipInfo | jq -r .loc)\", \"$(echo $ipInfo | jq -r .org)\", \"$(echo $ipInfo | jq -r .postal)\", \"$(echo $ipInfo | jq -r .timezone)\", \"$(echo $curlTime | jq -r .time_namelookup)\", \"$(echo $curlTime | jq -r .time_connect)\", \"$(echo $curlTime | jq -r .time_appconnect)\", \"$(echo $curlTime | jq -r .time_pretransfer)\", \"$(echo $curlTime | jq -r .time_redirect)\", \"$(echo $curlTime | jq -r .time_starttransfer)\", \"$(echo $curlTime | jq -r .time_total)\", \"$(date)\"]]}" \
  --compressed