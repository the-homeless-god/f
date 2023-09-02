#!/bin/bash

# Create init.sh file
cat > init.sh << 'EOL'
#!/bin/bash

# Env: Getting versions
node_version=$(node --version | sed 's/^v//')  # Remove 'v' from string
npm_version=$(npm --version)

# Env: Required versions
required_node_version="20.5.0"
required_npm_version="9.8.0"

# Env: Compare versions
if [ "$node_version" != "$required_node_version" ]; then
  echo "Error: required Node.js is $required_node_version. Your is $node_version."
  exit 1
fi

if [ "$npm_version" != "$required_npm_version" ]; then
  echo "Error: required npm is $required_npm_version. Your is $npm_version."
  exit 1
fi

# Calculate progress and display the progress bar
show_progress() {
  echo -n "["
  for i in $(seq 1 50); do
    if [ $i -le $(($1 / 2)) ]; then
      echo -n "#"
    else
      echo -n " "
    fi
  done
  echo -n "] $1%"
  echo
}

# Middleware function to log the steps
log_step() {
  echo "======================================"
  echo $1
  echo "======================================"
  show_progress $2
}

log_step "1. Create directory and initialize npm project" 14
mkdir -p application && cd application
npm init -y
npm install -D typescript@latest @types/node@latest ts-node@latest

log_step "2. Initialize TypeScript and create src directory" 28
npx tsc --init --outDir dist
mkdir -p src && cd src

log_step "3. Create and populate main file" 42
cat > index.ts << 'INNER_EOL'
import http from "http";

export const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ data: "It Works!" }));
});

server.listen(3000, () => {
  console.log("Server running on http://localhost:3000/");
});
INNER_EOL

log_step "4. Create and populate test file" 57
cat > index.test.ts << 'INNER_EOL'
import { server } from "./index";
import http from "http";
import assert from "assert";

const options = {
  hostname: "localhost",
  port: 3000,
  method: "GET"
};

const req = http.request(options, res => {
  let rawData = "";
  res.on("data", chunk => { rawData += chunk; });
  res.on("end", () => {
    assert.strictEqual(rawData, JSON.stringify({ data: "It Works!" }));
    console.log("Test Passed");
    server.close();
  });
});

req.on("error", error => {
  console.error("Test Failed:", error);
  server.close();
});

req.end();
INNER_EOL

cd ..

log_step "5. Add .gitignore" 71
echo "node_modules/" > .gitignore
echo "dist/" >> .gitignore

log_step "6. Add scripts to package.json" 85
npm pkg set scripts.start="node ./dist/index.js"
npm pkg set scripts.build="tsc"
npm pkg set scripts.dev="tsc --watch"
npm pkg set scripts.test="tsc && node ./dist/index.test.js"

log_step "8. Set Node.js and npm engine versions" 92
npm pkg set "engines.node=$required_node_version"
npm pkg set "engines.npm=$required_npm_version"

log_step "9. Enable npm strict mode" 95
echo 'strict-ssl=true' > .npmrc

log_step "10. Run the test" 100
npm test
EOL

# Make the script executable and execute it
chmod +x init.sh
./init.sh

# Check if everything is set up correctly
if [ -d "application" ] && [ -d "application/src" ] && [ -f "application/src/index.ts" ] && [ -f "application/src/index.test.ts" ]; then
    echo "All files and directories are set up correctly. Deleting init.sh..."
    rm init.sh
else
    echo "Something went wrong. Please check the logs. init.sh will not be deleted."
fi
