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
