const http = require('http');
const url = require('url');
const fs = require('fs');

// Create an HTTP server to capture the authorization code
const server = http.createServer((req, res) => {
  const queryObject = url.parse(req.url, true).query;

  if (queryObject.code) {
    console.log("Authorization code received!");
    fs.writeFileSync('/tmp/auth_code.txt', queryObject.code);  // Save the code to a temporary file

    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Authorization successful! You can close this tab.');
  } else {
    res.writeHead(400, { 'Content-Type': 'text/plain' });
    res.end('Authorization code not found.');
  }
});

// Listen on port 8080
server.listen(8080, () => {
  console.log('Server is running on http://localhost:8080');
});
