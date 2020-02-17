---
title: onion-omega-monitor-uci
#abbrlink: e1b6b199
tags:
---


###### simple spawn example
const spawn = require('child_process').spawn;
const uci = spawn('uci', ['show', 'network.wlan.ipaddr']);

uci.stdout.on('data', (data) => {
  console.log(`stdout: ${data}`);
});

uci.stderr.on('data', (data) => {
  console.log(`stderr: ${data}`);
});

uci.on('close', (code) => {
  console.log(`child process exited with code ${code}`);
});
#####


#### simple http client example
var querystring = require('querystring');
var http = require('http');
var fs = require('fs');

function PostCode(codestring) {
  // Build the post string from an object
  var post_data = querystring.stringify({
      'compilation_level' : 'ADVANCED_OPTIMIZATIONS',
      'output_format': 'json',
      'output_info': 'compiled_code',
        'warning_level' : 'QUIET',
        'js_code' : codestring
  });

  // An object of options to indicate where to post to
  var post_options = {
      host: 'closure-compiler.appspot.com',
      port: '80',
      path: '/compile',
      method: 'POST',
      headers: {
          'Content-Type': 'application/xwww-form-urlencoded',
          'Content-Length': Buffer.byteLength(post_data)
      }
  };

  // Set up the request
  var post_req = http.request(post_options, function(res) {
      res.setEncoding('utf8');
      res.on('data', function (chunk) {
          console.log('Response: ' + chunk);
      });
  });

  // post the data
  post_req.write(post_data);
  post_req.end();

}

// This is an async file read
fs.readFile('LinkedList.js', 'utf-8', function (err, data) {
 if (err) {
   // If this were just a small part of the application, you would
   // want to handle this differently, maybe throwing an exception
   // for the caller to handle. Since the file is absolutely essential
   // to the program's functionality, we're going to exit with a fatal
   // error instead.
   console.log("FATAL An error occurred trying to read in the file: " + err);
   process.exit(-2);
 }
 // Make sure there's data before we post it
 if(data) {
   PostCode(data);
 }
 else {
   console.log("No data to post");
   process.exit(-1);
 }
});
########

##### simple tcp client example
var net = require('net');

var client = new net.Socket();
client.connect(1337, '127.0.0.1', function() {
       console.log('Connected');
       client.write('Hello, server! Love, Client.');
});

client.on('data', function(data) {
       console.log('Received: ' + data);
       client.destroy(); // kill client after server's response
});

client.on('close', function() {
       console.log('Connection closed');
});
####
