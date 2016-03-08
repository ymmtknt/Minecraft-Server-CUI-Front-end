#!/bin/bash
# Minecraft Server CUI Front-end (prov.)
# (c) kentay MIT license
version="0.1.2"

################ ATTENTION ################
# In the case of OSX, bash is too old to execute this script.
# You have to install bash 4 or later and execute with the bash.
# e.g.) bash ./mscf.sh -p brabrabra...
# Or adjust interpreter on the first line of this script to you environment.
# e.g.) !/bin/bash -> !/usr/local/bin/bash

############## Default values ##############
############################################
server="./minecraft_server.jar" # server file
verbose=0 # if show latest log under menu, 1.
nologo=0 # if do not show header log, 1.
sname="minecraft_server" # screen session name
xmx="1024M" # XMX for JAVA
xms="1024M" # XMS for JAVA
java="java" # JAVA command
############################################
############################################

# if .ini file does not exist
#if [ ! -f "$(basename $0 .sh).ini" ] ; then
#  cat > $(basename $0 .sh).ini
#fi

# after ini file read
# get options
while getopts ":vnS:p:x:s:j:h" OPT; do
 case "${OPT}" in
   h)
     Usage
     exit 0
     ;;
   v)
     verbose=1
     ;;
   S)
     sname=$OPTARG
     ;;
   n)
     nologo=1
     ;;
   p)
     server=$OPTARG
     ;;
   x)
     xmx=$OPTARG
	   ;;
   s)
     xms=$OPTARG
	   ;;
   j)
     java=$OPTARG
     ;;
  esac
done

# global variables
menu=("Launch" "Stop" "Command" "Quit")
c=0 # counter how many times Draw was called
col=0 # selected menu number
defmsg="Select menu item..." # default status bar message
status="${defmsg}"
key="wait"
dir=$(dirname ${server})
file=$(basename ${server})

Usage(){
  clear
  Header
  Separater 75
cat <<EOD
Minecraft Server CUI Front-end ver. $version
Usage: $0 [-p server_file_path] [-S session_name] [-v] [-n] [-x memory_size] [-s memory_size] [-h]

p: Path to server file (${server})
S: Server session name as "screen -S" (${sname})
v: Verbose mode. Show latest server log under menu
n: No header log mode
j: JAVA command (${java})
x: XMX size for JAVA ($xmx)
s: XMS size for JAVA ($xms)
h: Help
EOD
  Separater 75
}

Header(){
cat <<EOD
██     ██ ███ ██   ██ ███████ ███████ ███████ ██████████ ████████ █████████
███   ███ ███ ███  ██ ███████ ███████ ███████ ██  ██  ██ ████████ █████████
█████████ ███ ████ ██ ██      ██      ██  ███ ████  ████ ██          ███
█████████ ███ ███████ ███████ ██      ███████ ███ ▄▄ ███ ████████    ███
██ ███ ██ ███ ██ ████ ██      ██      ██████▄ ██████████ ██          ███
██     ██ ███ ██  ███ ███████ ███████ ██  ███ ███    ███ ██          ███
██     ██ ███ ██   ██ ███████ ███████ ██  ███ ███    ███ ██          ███

                          ███ ███ ███ █ █ ███ ███
                          █   █   █ █ █ █ █   █ █
                          ███ ███ ███ █ █ ███ ███
                            █ █   ██▄ █ █ █   ██▄
                          ███ ███ █ █  █  ███ █ █

EOD
}

Draw(){
  local i
  # refresh display
  local cur=1
  [ $nologo -eq 0 ] && cur=$(Header | wc -l)
  echo -e "\033[${cur};1H"
  echo -en "\033[0J"
  local isact="inactive"
  [ $(ps | grep -c "${lcom}") -gt 1 ] && isact="active"

  # draw menu items
  # yes, actually beautiful one line if syntaxes. but bad readability...
  for (( i=0; i<${#menu[@]}; i++ )) ; do
    [ $i -eq $col ] && echo -ne "\033[7m" || echo -n ""
    echo -n "${menu[${i}]}"
    [ $i -eq $col ] && echo  -ne "\033[m" || echo -n ""
  	[ $i -lt $(( ${#menu[@]} -1 )) ] && echo -ne "    "
  done

  echo ""
  Separater 75
  echo -e "[Server] ${server} \033[4m${isact}\033[m"
  echo "[Session] ${sname}"
  [ $verbose -eq 1 ] && ShowLog
  Separater 75

  echo -n "${status}"
  c=$(( $c + 1 ))
  if [ $c -gt 6 ] ; then # status clear at 6 times Draw function called
    status="${defmsg}"
    c=0
  fi
}

ShowLog(){
  echo "[Latest log]"
  tail -n10 ./logs/latest.log
}

Separater(){
  local fc i
  if [ ! $# -eq 0 ] ; then
    [ $1 -lt 1 ] && fc=1 || fc=$1
  fi
  echo -ne "\033[4m"
  for (( i=0; i<${fc}; i++ )) ; do
    echo -n " "
  done
  echo -e "\033[m"
}

GetArrowKey(){
  while read -rsn1 -d$'\n' -t1 key; do # wait 1 sec to read key
    case "$key" in
    $'\x1b')
      read -rsn1 -t 0.01 k2 # read command on OSX's default bash can't be set millisecond -t option! suck bad!!
      if [[ "${k2}" == "[" ]] ; then
        read -rsn1 -t 0.01 k3
        key="${key}${k2}${k3}" # concatenate read keys
        break;
      fi
      if [[ ! $k2 ]] ; then
        key="esc"
        break;
      fi
      ;;
    '') # press Enter key
      key="enter"
      break;
      ;;
    ' ') # press Space key
      key="space"
      break;
      ;;
    esac
  done
}

LaunchServer(){
  local sc=$(screen -ls | grep -c "${sname}")
  [ $sc -eq 0 ] && screen -dmS $sname # when screen session $sname is not found, start screen session
  status="Launching server..."
  screen -p 0 -S $sname -X eval "stuff '${lcom}
'"
}

RestartServer(){
  local OPTIND w opt
  while getopts ":w:" opt; do
    case "${opt}" in
      w)
        w=$OPTARG
      ;;
    esac
  done
  shift $(( $OPTIND - 1))
  screen -p 0 -S $sname -X eval "stuff '/say server will be restarted.
  '"
  StopServer -c -w $w
  Draw
  sleep 2
  LaunchServer
  Draw
}

StopServer(){
  local i
  local OPTIND w c opt
  while getopts ":w:c" opt; do
    case "${opt}" in
      c)
        c=1
      ;;
      w)
        w=$OPTARG
      ;;
    esac
  done
  shift $(( $OPTIND - 1))

  for (( i=0; i < $w ; i++ )) ; do
    screen -p 0 -S $sname -X eval "stuff '/say server will be stopped after $(( $w - $i )) sec.
    '"
    Draw
    sleep 1
  done

  screen -p 0 -S $sname -X eval "stuff '/stop
'"
  [ $c -lt 1 ] && screen -r $sname -X quit
  status="Stopping server..."
}

Execute(){
  local sc
  case "${col}" in
    0) # launch the server
      local sa=$(ps | grep -c "${lcom}")
      if [ $sa -eq 1 ] ; then # when server is not active
        LaunchServer
      elif [ $sa -gt 1 ] ; then
        status="The server is probably already active."
      fi
      ;;
    1) # stop the server
      sc=$(screen -ls | grep -c "${sname}")
      if [ $sc -eq 1 ] ; then
        StopServer -w 10
      elif [ $sc -eq 0 ] ; then
        status="Server not found."
      fi
      ;;
    2) # send command to server
      sc=$(screen -ls | grep -c "${sname}")
      if [ $sc -eq 1 ] ; then
        status="Command: "
        Draw
    		read -r command
		    local flg=0
		    if [ $(echo "${command}" | grep -c '^[\s\/]\{0,\}stop') -gt 0 ] ; then
		      # if stop command sent from command session
          # Stop the server and quit the screen session
          StopServer -w $(echo "${command}" | ( read -a wt ; echo "${wt[1]}" | grep '^[0-9]\{1,3\}$'))
		      flg=1
		    fi
        # yes, contributers could add special commands here, such as "/restart", "/backup", and so on.
        if [ $(echo "${command}" | grep -c '^[\s\/]\{0,\}restart') -gt 0 ] ; then
        # like this.
          RestartServer -w $(echo "${command}" | ( read -a wt ; echo "${wt[1]}" | grep '^[0-9]\{1,3\}$'))
		      flg=1
		    fi
        # or to separate these commands from Command section is better than that?

		    if [ "${command}" != "" -a $flg -eq 0 ] ; then # if command was not null and not special commands.
    		  screen -p 0 -S $sname -X eval "stuff '${command}
'"
		      status="Sent '${command}' to server"
        else
          status="${defmsg}"
		    fi # in the case command was null, then do nothing.
      elif [ $sc -eq 0 ] ; then
        status="Server not found."
      fi
	    ;;
#	3) # connect server
#      if [ $sc -eq 1 ] ; then #attach screen
#	    screen -r $sname
#	  elif [ $sc -eq 0 ] ; then
#	    status="No server found."
#	  fi
#	  ;;
    3) # quit menu
      echo ""
      exit 0
      ;;
esac
}

Main(){
  while true; do
    Draw

    if GetArrowKey; then
      case "${key}" in
        $'\x1b[D' ) # press right
          col=$(( $col - 1))
          [ $col -lt 0 ] && col=0
	        key="wait"
	        status="${defmsg}"
          Draw
          ;;
        $'\x1b[C' ) # press left
          col=$(( $col + 1))
          [ $col -gt $(( ${#menu[@]} - 1)) ] && col=$(( ${#menu[@]} - 1))
	        key="wait"
	        status="${defmsg}"
          Draw
          ;;
#    $'\x1b[A' )
    # press up
#    ;;
#    $'\x1b[B' )
    # press down
#    ;;
        'enter' )
	        key="wait"
	        status="${defmsg}"
          Draw
          Execute
          ;;
        'esc' )
  	      key="wait"
  	      status="${defmsg}"
          Draw
#          Execute
          ;;
        'space' )
          key="wait"
          status="${defmsg}"
          Draw
#          Execute
          ;;
      esac
    fi

  done
}

Initialize(){
  clear

  cd $dir
  lcom="${java} -Xmx${xmx} -Xms${xms} -jar ./${file} nogui"
# echo $server
  if [ ! -f "${file}" ] ; then
    echo "Server file does not exist."
    exit 1
  fi



  [ $nologo -eq 0 ] && Header || echo "Minecraft server"

}

Initialize
Main
