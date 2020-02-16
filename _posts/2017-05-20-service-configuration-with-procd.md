---
title: Service configuration with procd
description: Service configuration with procd
tags:
  - OpenWrt
  - procd
  - Onion
  - Omega
date: 2017-05-20 08:13:36 +0100
---

In a previous instalment I talked about setting up services on an Onion Omega with the use of a basic init script. While this works fine for many applications, we can instead use **procd** scripts. Procd init scripts gives us many nice to use features by default such as a restart strategy and the ability to store and read configuration from the UCI system.

### Setting up
As example, lets say we'd want to create a Node.js app as a service and that this service can be configured with a message and a timeout in order for us to be reminded to get up from ur desks once in a while. Our service name will be **mynodeservice** and it depends on the following script

{% gist 65599194ca6b449f22e031ffa53d3eaa mynodeservice.js %}

Place it in `/var/mynodeservice` and test it by running on the Omega
```
$ node /var/mynodeservice.js <your-name>
```

### Creating a basic procd script

Now that we have a working script, we can make a service out of it. Create a file in `/etc/init.d/mynodeservice` with the following content

{% gist 65599194ca6b449f22e031ffa53d3eaa mynodeservice %}

First, it includes the common 'run commands' file `/etc/rc.common` needed for a service. This file defines several functions that can be used to manage the service lifecycle, it supports old style init scripts as well as procd scripts. In order to tell that we want to use the new style we then set the USE_PROCD flag.

The `START` option basically tell the system when the service should start and stop during startup and shutdown of OpenWRT.

This init script isn't very useful at the moment but it shows the basic building blocks on which we will develop the script further.

### Enabling the service

To tell OpenWRT that we have a new service we would need to run

```
$ /etc/init.d/mynodeservice enable
```
This will install a symlink for us in directory `/etc/rc.d/` called `S90mynodeservice` which point to our respective service script in `/etc/init.d/`. OpenWRT will start the services according the the order of `S*` scripts in `/etc/rc.d/`. To see the order you could simply run
```
$ ls -la /etc/rc.d/S*
...
```
It is useful to be able to influence the order of startup of services, if our service would be dependent on the network we'd make sure that
the START sequence 'index' is at least 1 more than the START sequence of the network service.

The same rules apply for the optional STOP parameters, only this time it defines in which order the services will be shutdown.
To see Which shutdown scripts are activated you can run
```
$ ls -la /etc/rc.d/K*
```

You always need to define a START or STOP sequence in your script (you can also define both). If you define a STOP sequence you also want to
define a stop_service() handler in the init script. This handler is usually taking care of cleaning up service resources or persistence of data needed when the service starts again.

### Testing the service

Finally, lets just test our service. Open a second shell to the OpenWRT device and run
```
$ logread -f
```
This will tail the system logs on the device.
then enable (if you havent done that yet), and start the service.
```
$ /etc/init.d/mynodeservice enable
$ /etc/init.d/mynodeservice start
```
After about 5 seconds we should see the message repeat itself in the log, but we didn't...
We still need to redirect stdout and stderr to logd in order to see the console.log output in the system logs.

{% gist 65599194ca6b449f22e031ffa53d3eaa mynodeservice-redirect %}

Now, when we restart we should see something like
```
$ logread -f
... ommitted ... node[20136]: Hey, You, it's time to get up
... ommitted ... node[20136]: Hey, You, it's time to get up
... ommitted ... node[20136]: Hey, You, it's time to get up
... ommitted ... node[20136]: Hey, You, it's time to get up
... ommitted ... node[20136]: Hey, You, it's time to get up
... ommitted ... node[20136]: Hey, You, it's time to get up
...
```

Setting up a service simple script like above with procd already gives us some advantages

* Common api to manage services
* The service will automatically start at every boot

### Service configuration

It's time to get more personal, and to that we will use OpenWRTs [UCI](https://wiki.openwrt.org/doc/uci) configuration interface. Create a configuration file `/etc/config/mynodeservice` with the following content

{% gist 65599194ca6b449f22e031ffa53d3eaa mynodeservice-uci %}

UCI will immediately pick this up and the config for our service can be inspected like
```
$ uci show mynodeservice
mynodeservice.hello=mynodeservice
mynodeservice.hello.name=Ninja
mynodeservice.hello.every='5000'
```
Also single options can be requested
```
$ uci get mynodeservice.hello.name
```
and we can also change specific configuration with UCI
```
$ uci set mynodeservice.hello.name=Knight
$ uci commit
```

Now, we'll introduce a couple of changes to the service script in order to read and use the configuration in our script.

### Loading service configuration

We can already pass configuration to the node script by passing arguments to it. The only thing we need to do is load the services matching configuration, store the values of the options we need into some variables
and pass them into the command that starts the script.

{% gist 65599194ca6b449f22e031ffa53d3eaa mynodeservice-config %}

We can pass new configuration by running
```
$ uci set mynodeservice.hello.name=Woodrow Wilson Smith
$ uci commit
```
Note that in the service script the arguments are quoted, which allows us to use spaces in the name option.
If we wouldn't do this, each part of the name would be treated as a separate argument.

Apart from the loading and passing of config to our script we also added
```
  ...
  procd_set_param file /etc/config/mynodeservice
  ...
```

With that line in place we are able to only restart the service whenever our configuration has changed.
```
$ /etc/init.d/mynodeservice reload
```

### Advanced options

There are a couple of more options that can be configured in a procd scripts 'instance block' that might be handy to know about.
I'll list a few here, but this is by no means covering everything.

* respawn

  respawn your service automatically when it died for some reason.
  ```
  procd_set_param respawn \
    ${respawn_threshold:-3600} \
    ${respawn_timeout:-5} ${respawn_retry:-5}
  ```
  In this example we respawn
  if process dies sooner than respawn_threshold, it is considered crashed and after 5 retries the service is stopped

* pidfile

  Configure where to store the pid file
  ```
  procd_set_param pidfile $PIDFILE
  ```

* env vars

  Pass environment variables to your process with
  ```
  procd_set_param env A_VAR=avalue
  ```
* ulimit

If you need to set ulimit for your process you can use
```
procd_set_param limits core="unlimited"
```
To see the system wide settings for ulimt on an OpenWRT device you can run
``` bash
$ ulimit -a
-f: file size (blocks)             unlimited
-t: cpu time (seconds)             unlimited
-d: data seg size (kb)             unlimited
-s: stack size (kb)                8192
-c: core file size (blocks)        0
-m: resident set size (kb)         unlimited
-l: locked memory (kb)             64
-p: processes                      475
-n: file descriptors               1024
-v: address space (kb)             unlimited
-w: locks                          unlimited
-e: scheduling priority            0
-r: real-time priority             0
```

* user

To change the user that runs the service you can use
```
procd_set_param user nobody
```
A Onion Omega only seems to have a 'root' user or 'nobody' as the process owner.

### Sources

* [procd basics](https://wiki.openwrt.org/inbox/procd-init-scripts)
* [procd reference](http://wiki.prplfoundation.org/wiki/Procd_reference)
* [procd configuration](https://wiki.openwrt.org/doc/devel/config-scripting)
* [OpenWRT boot process](https://wiki.openwrt.org/doc/techref/process.boot#init)
* [OpenWRT source](https://github.com/openwrt/openwrt)
* [Unified Configuration Interface (UCI)](https://wiki.openwrt.org/doc/uci)
