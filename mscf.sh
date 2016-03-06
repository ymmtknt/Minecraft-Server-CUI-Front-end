#!/bin/bash
# Minecraft Server CUI Front-end (prov.)
# (c) kentay MIT license

version=0.1

################################################
# Default values
################################################
server="./minecraft_server.jar" # server file
verbose=0 # if show latest log under menu, 1.
sname="minecraft_server" # screen session name
xmx="1024M" # XMX for JAVA
xms="1024M" # XMS for JAVA
java="java" # JAVA command
#################################################
#################################################

# if .ini file does not exist
#if [ ! -f "$(basename $0 .sh).ini" ] ; then
#  cat > $(basename $0 .sh).ini
#fi

Usage(){
  clear
  Header
  Separater 75
cat <<EOD
Minecraft Server CUI Front-end ver.$version
Usage: $0 [-p server_file_path] [-S session_name] [-v] [-x memory_size] [-s memory_size] [-h]

p: Path to server file ($server)
v: Verbose mode. Show latest server log under menu
S: Server session name as "screen -S" ($sname)
j: JAVA command ($java)
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
  clear # which is better? clear or reset.
  Header
  n=0
  isact="inactive"
  [ $(ps | grep -c "$lcom") -gt 1 ] && isact="active"
  echo ""
  for (( i=0; i<${#menu[@]}; i++ )) ; do
    if [ $i -eq $row ] ; then
     echo -ne "\033[7m"
    else
     echo -n ""
    fi

    echo -n "${menu[${i}]}"

    if [ $i -eq $row ] ; then
     echo  -ne "\033[m"
    else
     echo -n ""
    fi
	echo -ne "    "
  done
  echo ""
  Separater 75
  echo -e "[Server] $server \033[4m$isact\033[m"
  echo "[Session] $sname"
  if [ $verbose -eq 1 ] ; then
    ShowLog
  fi
  Separater 75
  echo -n "$status"
  c=$(( $c + 1 ))
  if [ $c -gt 6 ] ; then # status clear at 6 times Draw function called
    status=$defmsg
    c=0
  fi
}

ShowLog(){
#  echo "";
  echo "[Latest log]"
  tail -n10 ./logs/latest.log
}

Separater(){
  fc=1
  if [ $# -eq 0 ] ; then
    fc=1
  else
    [ $1 -lt 1 ] && fc=1 || fc=$1
  fi
  echo -ne "\033[4m"
  for (( i=0; i<${fc}; i++ )) ; do
    echo -n " "
  done
  echo -e "\033[m"
}

GetArrowKey(){
  while read -rsn1 -t 1 key; do
    case "$key" in
    $'\x1b')
    read -rsn1 k2
    if [[ "$k2" == "[" ]] ; then
      read -rsn1 k3
      key="$key$k2$k3"
      break;
    fi
    ;;
    "") # press Enter key
      key="enter"
      break;
    ;;
    esac
  done
}

Execute(){
  sc=$(screen -ls | grep -c "$sname")
#  lcom=''"$java"' -Xmx'"$xmx"' -Xms'"$xms"' -jar '"$server"' nogui'
  case "${row}" in
    0) # launch server
      sa=$(ps | grep -c "$lcom")
      if [ $sa -gt 1 ] ; then
        status="server is probably already active."
      elif [ $sa -eq 1 ] ; then # when server is not active
        [ $sc -eq 0 ] && screen -dmS $sname # when screen session $sname is not found, start screen session
        # launch server
          status="server is launching"
          screen -p 0 -S $sname -X stuff ''"$lcom"'
'
      fi
      ;;
    1)
    # stop server
      if [ $sc -eq 1 ] ; then #stop server
        screen -p 0 -S $sname -X eval 'stuff "/stop
"'
        screen -r $sname -X quit
        status="server is stopping."
      elif [ $sc -eq 0 ] ; then
        status="No server found."
      fi
      ;;
    2)
    # send command to server
      if [ $sc -eq 1 ] ; then #send commant
#        screen -r $sname
        status="Send command: "
        Draw
    		read -a command
	    	send=""
		    flg=0
		if [ ${#command[@]} -eq 1 ] ; then
		    fc=$command  # the case only one command was given.
		  else
		    fc=$command[0]
		  fi
			fc=$(echo "$fc" | grep -i '[\s\/]\{0,\}stop$') 		# /^[\s\/]\{0,}stop$/i
		if [ $fc != "" ] ; then
		# if stop command sent from command session
		status="stop command have to be sent from 'Stop' on the menu"
		flg=1
		fi
		for (( i=0; i<${#command[@]}; i++ )); do
		  send="$send ${command[${i}]}"
		done
		echo "$send"
		if [ $send != "" -a $flg -eq 0 ] ; then # if command was not null.
		  screen -p 0 -S $sname -X eval 'stuff "'"$send"'
"'
		  status="sent '$send' to server $fc"
		fi # in the case command was null, then do nothing.
      elif [ $sc -eq 0 ] ; then
        status="No server found."
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
#      echo ""
      clear
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
      row=$((row - 1))
      [ $row -lt 0 ] && row=0
	  key="wait"
	  status=$defmsg
      Draw
      ;;
    $'\x1b[C' ) # press left
      row=$((row + 1))
      [ $row -gt $((${#menu[@]} - 1)) ] && row=$((${#menu[@]} - 1))
	  key="wait"
	  status=$defmsg
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
	  status=$defmsg
      Draw
      Execute
      ;;
  esac
  fi

done
}

Initialize(){

dir=$(dirname ${server})
file=$(basename ${server})

cd $dir
lcom=''"$java"' -Xmx'"$xmx"' -Xms'"$xms"' -jar ./'"$file"' nogui'
echo $server
if [ ! -f "$file" ] ; then
  echo "server file does not exist."
  exit 1
fi

menu=("Launch" "Stop" "Command" "Quit")
row=0
defmsg="Select menu item..."
status=$defmsg
c=0 # counter for status clear
}

# after ini file read
while getopts :vS:p:x:s:j:h OPT; do
 case $OPT in
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

Initialize
Main
