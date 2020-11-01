---
title: Raspberry Pi camera setup
categories:
- Series
- Python
tags:
- OpenCV
- Python
- Raspberry Pi
- Picamera
date: 2020-11-01 17:32 +0100
---
The dark tinkering months have started again, and so I bought a 5 Mega pixel camera for my Raspberry Pi to use for learing OpenCV with Python. This article is a summary of how to set up the camera for wireless video streaming over your home wifi.

What you need:

* [Raspberry Pi 3](), other versions might work as well, please let me know in the comments
* [Raspberry Pi camera v1.3](), other versions might work as well, please let me know in the comments
* [balenaEtcher](https://www.balena.io/etcher/) or your referred to to flash an SD card
* [Raspberry Pi OS](https://www.raspberrypi.org/downloads/raspberry-pi-os/) downloaded.

## Headless RPI configuration

First we'll prepare an SD card with the help of e.g balenaEtcher to flash it with the latest minimal Raspberry Pi OS. Once the flashing is complete add and empty file named `ssh` to the SD card boot partition.
Also, add a file named `wpa_supplicant.conf` with the following content

```bash
country=<COUNTRY_CODE>
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
    ssid="<NETWORK_NAME>"
    psk="<NETWORK_PASSWORD>"
    scan_ssid=1
}
```

Be sure to edit the placeholders with the data specific to your usecase. The `scan_ssd=1` line is needed when you have a hidden network.

When these two files exist and have the correct setting (please make doubly sure) save and then eject the SD card, insert it to your Raspberry Pi, and power it up

## Client machine

For connecting to our server script, which runs on anather machine than the Raspberry Pi we need to gather some information. First will aquire the server ip. Run `ifconfig | grep "inet " | grep -v 127.0.0.1 | cut -d\  -f2` to check your device ip (this works for my mac, go to wherever this data can be found on your machine)

Check if the Raspberry Pi has connected to your wifi by running `nmap -sP <A.B.C.0>/24` where a, b and c are as in the IP you found in the previous step. When the Raspberry Pi is listed you can run `ssh-keygen -R raspberrypi.local` followed by `ssh pi@raspberrypi.local` this should prompt you for a password and with a correct password input, you should be loggen on the Raspberry Pi command line interface.

## Passwordless SSH

It's more user friendly and easier to securely connect over ssh by configuring keys.

Genereate a new key on the client machine with

```bash
ssh-keygen -f ~/.ssh/id_rsa_rpi
```

Then copy the public part to the rpi with

```bash
cat ~/.ssh/id_rsa_rpi.pub | ssh pi@raspberrypi.local 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
```

Add the key to your keychain so it will be picked up automatically when needed.

```bash
ssh-add -K ~/.ssh/id_rsa_rpi
```

Log out of the ssh session if you havent already and try to login via ssh again, you should get to the cli withouh supplying a password as the authorization is now done via ssh keys.

```bash
$ ssh pi@raspberrypi.local
Linux raspberrypi 5.4.51-v7+
...
```

## Camera setup

The camera I'll setup is a cheap 5 Mpixs camera bought from Amazon. It might work for others in the same way.

While in the RPi cli, run:

```bash
sudo raspi-config
```

In the menu select `Interfacing...` -> `Camera` and enable it. After changing this setting the rpi needs to reboot.

After the reboot, login to the rpi again and run `raspistill -v -o test.jpg` to check if everythign works as expected, its output should look like this.

```bash
"raspistill" Camera App (commit f97b1af1b3e6 Tainted)

Camera Name ov5647
Width 2592, Height 1944, filename test.jpg
Using camera 0, sensor mode 0

GPS output Disabled

Quality 85, Raw no
Thumbnail enabled Yes, width 64, height 48, quality 35
Time delay 5000, Timelapse 0
Link to latest frame enabled  no
Full resolution preview No
Capture method : Single capture

Preview Yes, Full screen Yes
Preview window 0,0,1024,768
Opacity 255
Sharpness 0, Contrast 0, Brightness 50
Saturation 0, ISO 0, Video Stabilisation No, Exposure compensation 0
Exposure Mode 'auto', AWB Mode 'auto', Image Effect 'none'
Flicker Avoid Mode 'off'
Metering Mode 'average', Colour Effect Enabled No with U = 128, V = 128
Rotation 0, hflip No, vflip No
ROI x 0.000000, y 0.000000, w 1.000000 h 1.000000
Camera component done
Encoder component done
Starting component connection stage
Connecting camera preview port to video render.
Connecting camera stills port to encoder input port
Opening output file test.jpg
Enabling encoder output port
Starting capture -1
Finished capture -1
Closing down
Close down completed, all components disconnected, disabled and destroyed
```

We can inspect the image on the client machine by running

```bash
scp -r pi@raspberrypi.local:/home/pi/test.jpg  ~/Downloads/test.jpg
```

## Streaming to host machine

The following example is using picamera and the code is straight from their documentation.
Create two files, client.py and server.py.

The `server.py` script contains

```python
# This example is based on the server code found in the picamera documentation
# https://picamera.readthedocs.io/en/release-1.13/recipes1.html#capturing-to-a-network-stream
# and has been adapted to work with opencv-python.
import io
import socket
import struct
import cv2
import numpy as np

server_socket = socket.socket()
server_socket.bind(('0.0.0.0', 8000))
server_socket.listen(0)
connection = server_socket.accept()[0].makefile('rb')

try:
    while True:
        image_len = struct.unpack(
            '<L', connection.read(struct.calcsize('<L')))[0]
        if not image_len:
            break

        image_stream = io.BytesIO()
        image_stream.write(connection.read(image_len))
        image_stream.seek(0)

        frame = cv2.imdecode(np.frombuffer(image_stream.read(), np.uint8), 1)

        cv2.imshow('frame', frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

finally:
    connection.close()
    server_socket.close()
```

and needs to run on the host machine where you like to view the video stream.
You should be able to run it with `python server.py`. It is dependend on `opencv-python` and `numpy` packages
which need to be installed before with e.g `pip`.

The `client.py` script needs to run on the RPi.

```python
# This example is the client code found in the picamera documentation
# https://picamera.readthedocs.io/en/release-1.13/recipes1.html#capturing-to-a-network-stream
import io
import socket
import struct
import time
import picamera

# Length of stream
recording_time = 30

client_socket = socket.socket()
client_socket.connect(('your.ip.address.here', 8000))
connection = client_socket.makefile('wb')
try:
    with picamera.PiCamera() as camera:
        camera.resolution = (640, 480)
        camera.framerate = 30
        time.sleep(2)
        start = time.time()
        stream = io.BytesIO()
        for foo in camera.capture_continuous(stream, 'jpeg',
                                             use_video_port=True):
            connection.write(struct.pack('<L', stream.tell()))
            connection.flush()
            stream.seek(0)
            connection.write(stream.read())
            # comment or remove for never ending stream.
            if time.time() - start > recording_time:
                break
            stream.seek(0)
            stream.truncate()
    connection.write(struct.pack('<L', 0))
finally:
    connection.close()
    client_socket.close()

```

Replace `your.ip.address.here` with your actual server ip that was found earlier. Then run it with `python client.py`. You might get an error saying

```bash
pi@raspberrypi:~ $ python client.py
Traceback (most recent call last):
  File "client.py", line 5, in <module>
    import picamera
ImportError: No module named picamera
```

In that case install the module with `sudo apt-get install python-picamera python3-picamera` and try again.

When succesful, on your host(where server.py is running) you should see a screen popup with the video stream.

## Cleaning up

You might have seen this message in the RPI when loggin in during experimentation:

```bash
SSH is enabled and the default password for the 'pi' user has not been changed.
This is a security risk - please login as the 'pi' user and type 'passwd' to set a new password.
```

To fix this add the following to the end of the `/etc/ssh/sshd_config` file (with e.g vim)

```
Match User !root
    PasswordAuthentication no
```

Also make sure that the following lines (in the same file) are uncommented and configured with the saem values

```
PasswordAuthentication no
...
ChallengeResponseAuthentication no
...
UsePAM yes
```

So that anything that requires root access (sudo) will still ask for a password.

## Conclusion

That's all. Next steps would be to play around with opencv functionality or just use the current setup to see how plants are growing.

## Sources

* [rpi os](https://www.raspberrypi.org/downloads/raspberry-pi-os/)
* [rpi ssh](https://www.raspberrypi.org/documentation/remote-access/ssh/README.md)
* [ISO 3166 codes](https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes)
* [ssh passwordless](https://www.raspberrypi.org/documentation/remote-access/ssh/passwordless.md)
* [picamera](https://picamera.readthedocs.io/en/release-1.13/index.html)