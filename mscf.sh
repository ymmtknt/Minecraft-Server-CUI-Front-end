#!/bin/bash
# Minecraft Server CUI Front-end (prov.)
# (c) kentay MIT license
version="0.1.2 rev.1"

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
#menu=("Launch" "Stop" "Command" "Setting" "Quit")
menu=("Launch" "Stop" "Command" "Quit")
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
  [[ $nologo -eq 0 ]] && cur=$(Header | wc -l)
  echo -e "\033[${cur};1H"
  echo -en "\033[0J"
  local isact="inactive"
  [[ $(ps | grep -c "${lcom}") -gt 1 ]] && isact="active"

  # draw menu items
  # yes, actually beautiful one line if syntaxes. but bad readability...
  for (( i=0; i<${#menu[@]}; i++ )) ; do
    [[ $i -eq $col ]] && echo -ne "\033[7m" || echo -n ""
    echo -n "${menu[${i}]}"
    [[ $i -eq $col ]] && echo  -ne "\033[m" || echo -n ""
  	[[ $i -lt $(( ${#menu[@]} -1 )) ]] && echo -ne "    "
  done

  echo ""
  Separater 75
  echo -e "[Server] ${server} \033[4m${isact}\033[m"
  echo "[Session] ${sname}"
  [ $verbose -eq 1 ] && ShowLog
  Separater 75

  echo -n "${status}"

}

ShowLog(){
  echo "[Latest log]"
  tail -n10 ./logs/latest.log
}

Separater(){
  local i
  local fc=0
  [[ $1 =~ ^[0-9]{1,3}$ ]] && fc=$1
  echo -ne "\033[4m"
  for (( i=0; i<${fc}; i++ )) ; do
    echo -n " "
  done
  echo -e "\033[m"
}

GetCommand(){
  local c
  command=""
  while GetKey 1 ; do
    case "${key}" in
      'esc')
        command=""
        break
        ;;
      'delete' | 'backspace')
        command=${command/%?/}
        c=""
        ;;
      'space')
        c=" "
        ;;
      'enter')
        break
        ;;
      "left" | "right" | 'up' | 'down')
        c=""
        ;;
      *)
       c=$key
        ;;
    esac
    command="${command}${c}"
    status="$1${command}"
  done
}

GetKey(){
  local OFS=$IFS
  local t
  Draw
  [[ $1 =~ [0-9].{0,1}[0-9]{0,3} ]] && t="-t $1" || t=""
  while IFS=$'\n' read -rsn1 $t key ; do
    case "${key}" in
    $'\x1b')
      read -rsn1 -t 0.01 k2 # read command on OSX's default bash can't be set millisecond -t option! suck bad!!
      if [[ $k2 == "[" ]] ; then
        read -rsn1 -t 0.01 k3
        case "${k3}" in
        'A')
          key="up"
          ;;
        'B')
          key="down"
          ;;
        'C')
          key="left"
          ;;
        'D')
          key="right"
          ;;
        *)
          key="${key}${k2}${k3}" # concatenate read keys
          ;;
        esac
        break
      elif [[ ! $k2 ]] ; then
        key="esc"
        break
      fi
      ;;
    $'\x20') # Space
      key="space"
      break
      ;;
    $'\x7f') # Delete
      key="delete"
      break
      ;;
    $'\x08') # Backspace
      key="backspace"
      break
     ;;
    '') # Enter
      key="enter"
      break
      ;;
    *)
      break
      ;;
    esac
  done
  IFS=$OFS
}

#Setting(){
#
#}

LaunchServer(){
  local sc=$(screen -ls | grep -c "${sname}")
  [[ $sc -eq 0 ]] && screen -dmS $sname # when screen session $sname is not found, start screen session
  status="Launching server..."
  Draw
  screen -p 0 -S $sname -X eval "stuff '${lcom}
'"
}

RestartServer(){
  local OPTIND w opt
  w=0
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
  sleep 2
  LaunchServer
}

StopServer(){
  local i
  local OPTIND w c opt
  w=0
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

  status="Stopping server..."
  Draw
  for (( i=0; i < $w ; i++ )) ; do
    screen -p 0 -S $sname -X eval "stuff '/say server will be stopped after $(( $w - $i )) sec.
    '"
    Draw
    sleep 1
  done

  screen -p 0 -S $sname -X eval "stuff '/stop
'"
  [[ $c -lt 1 ]] && screen -r $sname -X quit
}

Execute(){
  local sc
  case "${col}" in
    0) # launch the server
      local sa=$(ps | grep -c "${lcom}")
      if [[ $sa -eq 1 ]] ; then # when server is not active
        LaunchServer
      elif [[ $sa -gt 1 ]] ; then
        status="The server is probably already active."
      fi
      ;;
    1) # stop the server
      sc=$(screen -ls | grep -c "${sname}")
      if [[ $sc -eq 1 ]] ; then
        StopServer -w 10
      elif [[ $sc -eq 0 ]] ; then
        status="Server not found."
      fi
      ;;
    2) # send command to server
      sc=$(screen -ls | grep -c "${sname}")
      if [[ $sc -eq 1 ]] ; then
        local comwait="Command:"
		    local flg=0
        command=""
        status="${comwait}"
        Draw
        while GetCommand "${comwait}"; do
          flg=0
          case "${key}" in
            'esc')
              status="${defmsg}"
              break
              ;;
            'left' | 'right' | 'up' | 'down' )
              ;;
            *)

              ############ extended command sample ############
    		      if [[ $command =~ ^[\　/]{0,}[Ss][Tt][Oo][Pp][\　]{0,} ]] ; then
		          # if stop command sent from command session
              # Stop the server and quit the screen session
                StopServer -w $(echo "${command}" | cut -d " " -f 2 -s | grep '^[0-9]\{1,3\}$')
                break
    		      fi

              # yes, contributers could add special commands here, such as "/restart", "/backup", and so on.
              if [[ $command =~ ^[\　/]{0,}[Rr][Ee][Ss][Tt][Aa][Rr][Tt][\　]{0,} ]] ; then
              # like this.
                RestartServer -w $(echo "${command}" | cut -d " " -f 2 -s | grep '^[0-9]\{1,3\}$')
		            flg=1
		          fi
              # or to separate these commands from Command section is better than that?
              #################################################

	  	        if [[ $command != "" && $flg -eq 0 ]] ; then # if command was not null and not special commands.
      		      screen -p 0 -S $sname -X eval "stuff '${command}
'"
		          fi # in the case command was null, then do nothing.
              command="" # command reset
              sleep 0.1
              status="${comwait}"
              ;;
          esac

        done

      elif [[ $sc -eq 0 ]] ; then
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
    *) # quit menu
      echo ""
      exit 0
      ;;
esac
}

Main(){
  local c=0
  while true; do
    if GetKey 1 ; then
      case "${key}" in
        'right' ) # press right
          col=$(( $col - 1))
          [[ $col -lt 0 ]] && col=0
	        key="wait"
	        status="${defmsg}"
          ;;
        'left' ) # press left
          col=$(( $col + 1))
          [[ $col -gt $(( ${#menu[@]} - 1)) ]] && col=$(( ${#menu[@]} - 1))
	        key="wait"
	        status="${defmsg}"
          ;;
#    'up' )
    # press up
#    ;;
#    'down' )
    # press down
#    ;;
        'enter' )
	        key="wait"
	        status="${defmsg}"
          Execute
          Draw
          ;;
        'esc' )
  	      key="wait"
  	      status="${defmsg}"
          ;;
        'space' )
          key="wait"
          status="${defmsg}"
          ;;
          *)
      esac
    fi
    if [[ $(( $c + 1 )) -gt 3 ]] ; then # status clear at 3 times Draw function called
      status="${defmsg}"
      c=0
    else
      c=$(( $c + 1 ))
    fi
  done
}

Initialize(){

  cd $dir
  lcom="${java} -Xmx${xmx} -Xms${xms} -jar ./${file} nogui"

  if [[ ! -f $file ]] ; then
    echo "Server file does not exist."
    exit 1
  fi

  clear
  [[ $nologo -eq 0 ]] && Header || echo "Minecraft server"
  Draw
}

Initialize
Main
