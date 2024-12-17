CLIENT_ID=$1
CLIENT_SECRET=$2
COOKIE_SECRET=$3
TENANT_ID=$4
REDIRECT_URI=http://localhost:8080/callback
SCOPE="openid profile email User.Read"
STATE="openssl rand -hex 12"


# Step 1: Open the authorization URL in the browser
AUTH_URL="https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/authorize?client_id=${CLIENT_ID}&response_type=code&redirect_uri=${REDIRECT_URI}&response_mode=query&scope=${SCOPE}&state=${STATE}"

echo "Opening the authorization URL in your browser..."
xdg-open "$AUTH_URL" 2>/dev/null || open "$AUTH_URL" || echo "Please open this URL manually: $AUTH_URL"

# Step 2: Start the Node.js server to capture the authorization code
echo "Starting the Node.js server to capture the authorization code..."

node ./scripts/oauth2/get_token_server.js &  # Start the Node.js server in the background
NODE_PID=$!  # Capture the process ID to stop it later

# Wait until the authorization code is captured (server will write it to /tmp/auth_code.txt)
while [ ! -f /tmp/auth_code.txt ]; do
  sleep 1
done

# Read the authorization code from the file
AUTHORIZATION_CODE=$(cat /tmp/auth_code.txt)
rm /tmp/auth_code.txt  # Clean up the temporary file

# Stop the Node.js server
kill $NODE_PID

echo "Authorization code captured: $AUTHORIZATION_CODE"

# Step 3: Exchange the authorization code for an ID token
echo "Exchanging authorization code for ID token..."

response=$(curl -s -X POST https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token \
-H "Content-Type: application/x-www-form-urlencoded" \
-d "client_id=${CLIENT_ID}" \
-d "scope=${SCOPE}" \
-d "code=${AUTHORIZATION_CODE}" \
-d "redirect_uri=${REDIRECT_URI}" \
-d "grant_type=authorization_code" \
-d "client_secret=${CLIENT_SECRET}")

# Extract the ID token from the response
id_token=$(echo $response | jq -r '.id_token')

# Check if the ID token is available and display it
if [ "$id_token" != "null" ]; then
  echo "ID Token: $id_token"
  # store the token in a temporary file
  echo $id_token > /tmp/id_token.txt
  echo "Decoded token:"
  echo $id_token | awk -F. '{print $2}' | base64 -d 2>/dev/null | jq '.'
else
  echo "Error retrieving ID token. Response:"
  echo $response
fi
