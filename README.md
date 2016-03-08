# Minecraft Server CUI Front-end (prov.)
This is front-end shell script for Minecraft server nogui mode. Name of this script is provisional.  
![screenshot1](screenshot1.png)  
This image is on mac terminal.app with Homebrew profile (Andale Mono font).

## Installation  
1)In the case of OSX, bash is too old to execute this script. You have to install bash 4 or later version (Please google how to install new bash on OSX).  
e.g.) `brew install bash`  
And execute with the bash,  
e.g.) `bash ./mscf.sh -p blablabla...`  
Or adjust interpreter on the first line of this script to you environment.  
e.g.) `#!/bin/bash -> #!/usr/local/bin/bash`

2) This script execute `screen` such as `screen -S minecraft_server`. You have to install `screen` at first. `apt-get install screen` etc.

3) Put this script anywhere you like and `chmod 755` this .sh file.

4) If you want to set default values (and execute without any options), You have to edit .sh file a little bit. Open .sh file in text editor and find "Default values" section. Adjust values to your environment.  

5) Done!

## Usage
Execute with following options if you need.  
[-p server_file_path] [-S session_name] [-v] [-n] [-x memory_size] [-s memory_size] [-h]

p: Path to server file  
S: Server session name as `screen -S`  
v: Verbose mode. Show latest server log under menu  
n: No header log mode  
j: JAVA command  
x: XMX size for JAVA  
s: XMS size for JAVA  
h: Help

e.g.) `./mscf.sh -v -p ./minecraft_server.1.9.jar -S session_name`

On the front-end, you can lunch/stop the server, send commands to the server. Choose your order from menu using left and right key and enter.
After quit the front-end, server continues to operate on screen with session name given as `-S` option or default value by the script. You can resume the front-end when you execute the script with the same options. Of course, You can attach the screen by `screen -r` with session name.

## To-do list

|priority|works|
|-----|----|
|B|external .ini file. (but it is not beautiful, isn't it?)|
|C|setting section. (for resuming the script without any options, .ini file is needed.)|
|C|add expanded commands|
|C|i18n|

## Change log

- ver. 0.1.2  
**adding** expanded command `restart`  
and you can give first argument ([0-9]{1,3}) to `stop`/`restart` as waiting time for stop/restart server.  
e.g.) In command section, if you input `stop 10` then server will be stopped after 10 seconds.  
**change** internal processing  
**fix** some bugs

- ver. 0.1.1 revision 1  
**change** internal processing  

- ver. 0.1.1  
**adding** no logo mode  
**change** display clearing method  
**fix** some bugs

- ver. 0.1  
first published version

(c) kentay MIT license
