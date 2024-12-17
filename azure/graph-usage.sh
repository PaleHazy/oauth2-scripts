#!/bin/bash

# Read the ID token from the temporary file
id_token=$(cat /tmp/id_token.txt)

if [ -z "$id_token" ]; then
  echo "No ID token found. Please run get_token.sh first."
  exit 1
fi

# Call Microsoft Graph API to get user details
response=$(curl -s -X GET \
  'https://graph.microsoft.com/v1.0/me' \
  -H "Authorization: Bearer $id_token" \
  -H "Content-Type: application/json")

# Check if the response contains an error
if echo "$response" | jq -e 'has("error")' > /dev/null; then
  echo "Error calling Microsoft Graph API:"
  echo "$response" | jq '.'
  exit 1
fi

# Pretty print the user details
echo "User Details:"
echo "$response" | jq '.'
