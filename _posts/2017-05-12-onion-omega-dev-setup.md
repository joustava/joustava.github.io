---
title: Developing with an Onion Omega
description: Setting up a simple development environment for Onion Omega
draft: false
tags:
  - Omega
  - Node.js
  - rsync
  - OpenWrt
date: 2017-05-12 08:07:33 +0100
---
This article will go through the steps to setup a simple development environment for the Onion Omega. With the help of some simple scripts and trivial configuration it is possible to increase the speed of the development cycle. Instead of ssh-ing into the device and using vi(m), after completion of the setup, you will be able to develop with the tools you are used to, test the code, and deploy to the Onion Omega in one fluent motion.

### Example application

To have some code to deploy, first create a project folder and add a couple of directories to it to keep things organized.
``` bash
$  mkdir myproject
$  mkdir myproject/src
$  mkdir myproject/scripts
$  mkdir myproject/test
```

You can name the project root directory to your liking, but the rest of the article will assume `myproject` to be the name of the project.

Now, in `./src` create the file `sensor.js` with the following content
``` javascript
var net = require('net');
var client = new net.Socket();

var PORT = 13370; //process.argv[2];
var HOST = '192.168.178.20'; //process.argv[1];
var send;

client.connect(PORT, HOST, function() {
	console.log('Connected');

  var send = setInterval(function(){
    client.write(`[${Date.now()}] - message\n`);
  }, 1500);

});

client.on('close', function() {
  clearInterval(send);
	console.log('Connection closed');
});

```

This node script will attempt to connect to a server and periodically send a message.

### SSH keys

Deployment should be as smooth as possible so we do not want to type credentials on every deploy. However, we most probably want to secure the device so that it is not that trivial to deploy to it.

First, let's create and copy a public ssh key

    $ ssh-keygen

This will ask you for some information, and then  creates and  saves a public key in `/home/<user>/.ssh/id_rsa.pub`.

Next, we need to upload this public key to the omega

    $ ssh-copy-id -i ~/.ssh/id_rsa.pub remote-host

When you started out with a factory onion remote-host is something like `omega-13e2.local`.
For the key to work on the omega we need one extra step. OpenWRT looks for the keys in `/etc/dropbear/authorized_keys` so we need to copy/move the authorized_key file

    $ mv .ssh/authorized_keys /etc/dropbear/authorized_keys

To check if it works, just try to ssh into the omega

    $ ssh root@remote-host

This should let you login to the omega without asking you for credentials, if however a passphrase was set on the ssh key this would still have to be typed at least once.

Even though this work fine, we still are able to login with the credentials, this might be a security risk, therefore we'll disable password login by executing
```
  $ uci export dropbear
  package dropbear

  config dropbear
  	option PasswordAuth 'on'
  	option RootPasswordAuth 'on'
  	option Port '22'

  $ uci set dropbear.@dropbear[0].PasswordAuth=0
  $ uci set dropbear.@dropbear[0].RootPasswordAuth=0
  $ uci commit dropbear
  $ uci export dropbear
  package dropbear

  config dropbear
  	option Port '22'
  	option PasswordAuth '0'
  	option RootPasswordAuth '0'

  $ cat /etc/config/dropbear

  config dropbear
  	option Port '22'
  	option PasswordAuth '0'
  	option RootPasswordAuth '0'

  $ /etc/init.d/dropbear restart
```

### Create deploy script

With the example project and ssh keys set up we can now look at deployment. The deployment will be done with the help of a script which leverages rsync to sync our project source to a dedicated path on the onion.

Create a `deploy.sh` file in the *scripts* directory with the following content
```
#!/bin/bash

if [[ $# -eq 0 ]];  then
        echo "Please specify host";
elif [[ $# -eq 1 ]]; then
      echo "executing dry-run to $1"
      rsync --dry-run -a --force --delete --progress \
        --exclude-from=.gitignore -e "ssh -p22" ./src/ $1:/var/sensor
elif [[ $# -eq 2 ]]; then
      echo "executing $2 deploy to: $1:/var/sensor"
      rsync -a --force --delete --progress \
        --exclude-from=.gitignore -e "ssh -p22" ./src/ "$1:/var/sensor"
fi
```

The script enable us to do a couple of things. The first is a deployment dry run. Running the script without only the host argument will give information about what would be done on this deploy but not do the actual deploy.

```
$ ./scripts/deploy.sh root@omega-1e13.local
```

The script will only sync the content of the src directory to */var/sensor* on the Omega.

To make a real deploy, a second argument must be passed.
```
$ ./scripts/deploy.sh root@omega-1e13.local production
```
The actual value of the second argument doesn't matter at this point, but could be used to enable extra options on deploy, such as minifying or generating documentation. The source can now be found on the Omega in the /var/sensor directory. Note that this directory is actually a symlink to /tmp on the device.

Possible enhancements to the script that I'll leave to the reader are e.g

* checking space on device before deploy
* check if node is installed before deploy

### Init script

We can deploy now, but you might notice that while the source gets updated automatically we still need to restart the node process by hand. To fix this we can create an init script. A basic init script looks like
```
  #!/bin/sh /etc/rc.common

  APP_PATH="/var/sensor/index.js"
  NAME=sensor
  DESC="Sensor"
  PIDFILE=/var/run/$NAME.pid

  START=90
  STOP=90

  start() {
        printf "%-50s" "Starting $NAME..."
        PID=`node $APP_PATH > /dev/null 2>&1 & echo $!`
        if [ -z $PID ]; then
            printf "%s\n" "Fail"
        else
            echo $PID > $PIDFILE
            printf "%s\n" "Ok"
        fi
  }

  stop() {
        printf "%-50s" "Stopping $NAME"
        PID=`cat $PIDFILE`
        if [ -f $PIDFILE ]; then
            kill -HUP $PID
            printf "%s\n" "Ok"
            rm -f $PIDFILE
        else
            printf "%s\n" "pidfile not found"
        fi
  }
```
This script should be placed on the Omage at `/etc/init.d/sensor`, where sensor is our made up service name. To enable the script we first need to run
```
$ /etc/init.d/sensor enable
```
The service can now be started with
```
$ /etc/init.d/sensor start
```
To restart the service after each deploy we could add the following lines to the deploy script directly after line 10.
```
    ssh $1 -t /etc/init.d/sensor stop;
    ssh $1 -t /etc/init.d/sensor start
```

### See it in action

To see it all in action first figure out your development machines ip with `nmap -sn 192.168.x.0/24`.
Your ip may vary. Run a tcp server on your dev machine for quick verification with `nc -l 13370`, where the last number is the port that the client expects to send its data to. This will in run a simple tcp server that can be reached by `<ip>:<port>`.
Now deploy your latest changes with the deploy script, this should start the client. Make sure the
PORT and HOST variables are set to match the tcp server you just started.

The TCP server output should now show the data that is send periodically by the client.

## Testing

I'll leave the testing part as an exercise to the user. The test do not need to be deployed to the device, but they would need to be run before deployment. A simple line could be added to both the dry run and actual deployment blocks. For example when adding a package.json (with `npm init`) to the project you'd run the tests with

    $ npm test

Which would then run whatever you configured in the package.json test script.

As the storage is limited on the Omega (when not using external storage) I do not install any node modules on the Omega and only use the features that are listed in the Node.js documentation. The test however do probably depend on testing modules such as mocha, but these would be defined in the package.json as devDependencies and would be run on the host (development machine).

## Sources

* [Onion](https://onion.io/), Invention Platform for IoT.
* [OpenWrt](https://openwrt.org/), an embedded operating system based on Linux.
* [Secure Shell (SSH)](https://www.openssh.com/), a cryptographic network protocol.
* [rsync](https://rsync.samba.org/), a utility for efficiently transferring and synchronizing files across computer systems.
* [Unified Configuration Interface](https://wiki.openwrt.org/doc/uci) (UCI), intended to centralize the configuration of OpenWrt.
* [Node.js](https://nodejs.org/en/), event-driven I/O server-side JavaScript environment based on V8.
