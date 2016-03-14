#!/bin/bash
# Minecraft Server CUI Front-end (prov.)
# (c) kentay MIT license
version="0.1.3"

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
session="minecraft_server" # screen session name
xmx="1024M" # XMX for JAVA
xms="1024M" # XMS for JAVA
java="java" # JAVA command
inifile="./mscf.ini"
############################################
############################################


# get options
while getopts ":vnS:p:x:s:j:i:h" OPT; do
 case "${OPT}" in
   h)
     Usage
     exit 0
     ;;
   v)
     verbose=1
     ;;
   S)
     session=$OPTARG
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
   i)
     inifile=$OPTARG
     ;;
  esac
done

# global variables
menu=("Launch" "Stop" "Command" "Setting" "Quit")
col=0 # selected menu number

SetIniVal(){
  local k v
  inival=$( cat << EOS
[General]
nologo=${nologo}
verbose=${verbose}
[Server]
server=${server}
session=${session}
[JAVA]
java=${java}
xmx=${xmx}
xms=${xms}
EOS
)
}

ReadIniFile(){

filedata=$( cat ${inifile})
inival=$(cat <<EOS
${inival}
${filedata}
EOS
)

}

SetIniVal
[[ -f $inifile ]]  && ReadIniFile

OFS=$IFS
while IFS='=' read k v ; do
  if [[ $k =~ ^\[.{1,}\]$ && ! $k =~ ^\[.{0,}\s{1,}.{0,}\]$ ]] ; then
    sec=$( echo "${k}" | sed -e 's/^\[\(.\{1,\}\)\]/\1/g'  )
    if [[ $(eval echo "\${#__${sec}[@]}") -eq 0 ]] ; then
      seclist+=(${sec})
      eval "declare -A __${sec}"
    fi
  elif [[ "${v}" && "${sec}" ]] ; then
    if [[ ! $(eval echo "\${__${sec}[${k}]}") ]] ; then
      eval "__${sec}list+=(${k})"
    fi
      eval "__${sec}[${k}]=${v}"
      eval "${k}=${v}"
 fi
done << EOS
$inival
EOS
IFS=$OFS

declare -A com
com["Default"]="Select menu item..." # default status bar message
com["ServerNotFound"]="Server file does not exist."
com["CommandNotFound"]="Command does not exist."
com["LaunchingServer"]="Launching server..."
com["StoppingServer"]="Stopping server..."
com["ServerIsActive"]="Server is probably already active."
com["ServerIsNotAvtive"]="Server is probably not active."
com["ComWait"]="Command:"
com["SelectValue"]="Select value..."
com["ChangeValue"]="Change value:"
com["InvalidValue"]="Invalid value"
status="${com["Default"]}"

key="wait"
dir=$(dirname ${server})
file=$(basename ${server})
lcom="${java} -Xmx${xmx} -Xms${xms} -jar ./${file} nogui"

Usage(){
  clear
  Header
  Separater 75
cat <<EOD
Minecraft Server CUI Front-end ver. $version
Usage: $0 [-p server_file_path] [-S session_name] [-v] [-n] [-x memory_size] [-s memory_size] [-i ini_file_path] [-h]

p: Path to server file (${server})
S: Server session name as "screen -S" (${session})
v: Verbose mode. Show latest server log under menu
n: No header log mode
j: JAVA command (${java})
x: XMX size for JAVA ($xmx)
s: XMS size for JAVA ($xms)
i: Path to ini file (${inifile})
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
  local OPTIND t opt

  while getopts ":t:" opt; do
    case "${opt}" in
      t)
        t=$OPTARG
      ;;
    esac
  done
  shift $(( $OPTIND - 1))

  # refresh display
  # moving cursor
  local cur=1
  if [[ $nologo -eq 0 ]] ; then
    cur=$(Header | wc -l)
    echo -e "\033[${cur};1H"
    echo -en "\033[0J"
  else
    echo -en "\033[${cur};1H"
    echo -en "\033[0J"
    echo "Minecraft server"
  fi

  ShowMenu

  Separater 75
  if [[ ! $t ]] ; then
    ShowServerInfo
    ShowLog
  else
    echo -e "${t}"
  fi

  Separater 75
  echo -ne "${status}"

}

ShowLog(){
  if [[ $verbose -eq 1 ]] ; then
    echo "[Latest log]"
    tail -n10 ./logs/latest.log
  fi
}

ShowMenu(){
  # draw menu items
  local i
  for (( i=0; i<${#menu[@]}; i++ )) ; do
    [[ $i -eq $col ]] && echo -ne "\033[7m" || echo -n ""
    echo -n "${menu[${i}]}"
    [[ $i -eq $col ]] && echo  -ne "\033[m" || echo -n ""
  	[[ $i -lt $(( ${#menu[@]} -1 )) ]] && echo -ne "    "
  done
  echo ""
}

ShowServerInfo(){
  local isact="inactive"
  [[ $(ps | grep -c "${lcom}") -gt 1 ]] && isact="active"
  echo -e "[Server] ${server} \033[4m${isact}\033[m"
  echo "[Session] ${session}"
  echo "[Java] ${lcom}"
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

  local OPTIND t="" h opt

  while getopts ":t:h:" opt; do
    case "${opt}" in
      t)
        t=$OPTARG
        ;;
      h)
        h=$OPTARG
        ;;
    esac
  done
  shift $(( $OPTIND - 1))

  local c cur=$(( ${#h} )) cc cp
  command="" #command cancel
  while true; do
    Draw -t "${t}"
    if GetKey 1 ; then
    case "${key}" in
      'esc')
        command=""
        break
        ;;
      'delete' | 'backspace') # separate "delete" and "backspace"? On OSX, there isn't "backspace" and "delete" is functioning as "backspace"
        cur=$(( $cur - 1 ))
        [[ $cur -lt $(( ${#h} )) ]] && cur=$(( ${#h} ))
        c=""
        cc=$(( $cur - ${#h} ))
        command=$( echo "${command}" | sed -e "s/^\(.\{$cc\}\).\(.\{0,\}\)$/\1\2/g" )
        ;;
      'enter')
        break
        ;;
      'left')
        c=""
        cur=$(( $cur - 1 ))
        [[ $cur -lt $(( ${#h} )) ]] && cur=$(( ${#h} ))
        ;;
      'right')
        c=""
        cur=$(( $cur + 1 ))
        [[ $cur -ge $(( ${#h} + ${#command} + 1 )) ]] && cur=$(( ${#h} + ${#command} + 1 ))
        ;;
       'up' | 'down')   # add readline function?
        c=""
        ;;
      '')
        c=""
        ;;
      *)
        c=$key
        cur=$(( $cur + 1 ))
        if [[ $cur -ge $(( ${#h} + ${#command} )) ]] ; then # if cursor is on the end of the string
          command="${command}${c}"
        else
          cc=$(( $cur - ${#h} - 1 ))
          command=$( echo "${command}" | sed -e "s/^\(.\{$cc\}\)\(.\{0,\}\)$/\1$c\2/g" )
        fi
        ;;
    esac

    # moving cursor position
    [[ $cur -lt $(( ${#h} + ${#command} )) ]] && cp="\x1b[$(( ${#h} + ${#command} - $cur ))D" || cp=""

    [[ $c != "" || $key == "left" || $key == "right" || $key == "delete" || $key == "backspace" ]] && status="${h}${command}${cp}"
  fi
  done
}

GetKey(){
  local OFS=$IFS
  local t

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
          key="right"
          ;;
        'D')
          key="left"
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
      key=" "
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

2DArray(){
  local a
  eval a='${'$1_$2'['$3']}'
  echo $a
}


WriteIniFile(){
  SetIniVal
  echo "${inival}" > ${inifile}
  dummy=""
}


Setting(){
  local k v j i sec echolist

  while true ; do

    strs=$( echo -n "")
    j=0
    for sec in ${seclist[@]} ; do
      strs="${strs}[${sec}]\n"
      for (( i=0 ; i<$(eval echo "\${#__${sec}list[@]}") ; i++ )) ; do
        k=$(eval echo "\${__${sec}list[${i}]}")
        echolist+=(${k})
        if [[ $j -eq $row ]] ; then
          cf="\033[7m"
          cb="\033[m"
        else
          cf=""
          cb=""
        fi
        strs="${strs}${cf}  ${k}: "$(eval "echo -e \"\${$k}\"")"${cb}\n"
        j=$(( $j + 1 ))
      done
    done

    Draw -t "${strs}"
    if GetKey 1; then
      case ${key} in
      'esc')
        WriteIniFile # save ini values
        # variables reset
        unset echolist
        key=""
        status="${com["Default"]}"
        break
        ;;
      'up')
        row=$(( $row - 1 ))
        [[ $row -lt 0 ]] && row=0
        ;;
      'down')
        row=$(( $row + 1 ))
        [[ $row -ge ${#echolist[@]} ]] && row=$(( ${#echolist[@]} - 1 ))
        ;;
      'enter' | ' ')
        case ${echolist[${row}]} in
          'nologo')
            nologo=$(( 1&~nologo ))
            echo -e "\033[1;1H\033[K"
            if [[ $nologo -eq 0 ]] ; then
              for (( i=1 ; i<$(Header | wc -l) ; i++ )) ; do
                echo -e "\033[${i};1H\033[K"
              done
              echo -en "\033[1;1H\033[K"
              Header
            fi
          ;;
          'verbose')
            verbose=$(( 1&~verbose))
          ;;
          'server')
            status="${com["ChangeValue"]}"
            GetCommand -t "${strs}" -h "${com["ChangeValue"]}"
             [[ -f ${command} ]] && eval "${echolist[${row}]}=${command}" || status="${com["ServerNotFound"]}"
          ;;
          'session')
            status="${com["ChangeValue"]}"
            GetCommand -t "${strs}" -h "${com["ChangeValue"]}"
            if [[ ${command} =~ ^[a-zA-Z0-9_]{1,}$ ]] ; then
              screen -p 0 -S :${session}: -X sessionname :${command}:
              eval "${echolist[${row}]}=${command}"
            else
              status="${com["InvalidValue"]}"
            fi
          ;;
          'java')
            status="${com["ChangeValue"]}"
            GetCommand -t "${strs}" -h "${com["ChangeValue"]}"
            [[ $(type -a "${command}" 2> /dev/null ) != "" ]] && eval "${echolist[${row}]}=${command}" || status="${com["CommandNotFound"]}"
            ;;
          'xmx' | 'xms')
            status="${com["ChangeValue"]}"
            GetCommand -t "${strs}" -h "${com["ChangeValue"]}"
             [[ ${command} =~ ^[0-9]{1,4}[mMgG]$ ]] && eval "${echolist[${row}]}=${command}" || status="${com["InvalidValue"]}"
          ;;
          *)
          ;;
        esac
        ;;
      esac
      key=""
    fi
    # variables reset
    unset echolist
    if [[ $(( $c + 1 )) -gt 3 ]] ; then # status clear at 3 times Draw function called
      status="${com["SelectValue"]}"
      c=0
    else
      c=$(( $c + 1 ))
    fi
  done

}

LaunchServer(){
  local sc=$(screen -ls | grep -c :${session}:)
  [[ $sc -eq 0 ]] && screen -dmS :${session}: # when screen session $session is not found, start screen session
  status="${com["LaunchingServer"]}"
  Draw
  screen -p 0 -S :${session}: -X eval "stuff '${lcom}
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
  screen -p o -S :${session}: -X eval "stuff '/say server will be restarted.
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

  status="${com["StoppingServer"]}"
  Draw
  for (( i=0; i < $w ; i++ )) ; do
    screen -p 0 -S :${session}: -X eval "stuff '/say server will be stopped after $(( $w - $i )) sec.
    '"
    Draw
    sleep 1
  done

  screen -p 0 -S :${session}: -X eval "stuff '/stop
'"
  [[ $c -lt 1 ]] && screen -p o -S :${session}: -X quit
}

Execute(){
  local sc
  case "${col}" in
    0) # launch the server
      local sa=$(ps | grep -c "${lcom}")
      if [[ $sa -eq 1 ]] ; then # when server is not active
        LaunchServer
      elif [[ $sa -gt 1 ]] ; then
        status="${com["ServerIsActive"]}"
      fi
      ;;
    1) # stop the server
      sc=$(screen -ls | grep -c :${session}:)
      if [[ $sc -eq 1 ]] ; then
        StopServer -w 10
      elif [[ $sc -eq 0 ]] ; then
        status="${com["ServerNotFound"]}"
      fi
      ;;
    2) # send command to server
      sc=$(screen -ls | grep -c :${session}:)
      if [[ $sc -eq 1 ]] ; then
		    local flg=0
        local command=""
        status="${com["ComWait"]}"
        Draw
        while GetCommand -h "${com["ComWait"]}" ; do
          flg=0
          case "${key}" in
            'esc')
              status="${com["Default"]}"
              break
              ;;
            'left' | 'right' | 'up' | 'down' )
              ;;
            *)

              ############ extended command sample ############
    		      if [[ $command =~ ^[\s/]{0,}[Ss][Tt][Oo][Pp][\s]{0,} ]] ; then
		          # if stop command sent from command session
              # Stop the server and quit the screen session
                StopServer -w $(echo "${command}" | cut -d " " -f 2 -s | grep '^[0-9]\{1,3\}$')
                break
    		      fi

              # yes, contributers could add special commands here, such as "/restart", "/backup", and so on.
              if [[ $command =~ ^[\s/]{0,}[Rr][Ee][Ss][Tt][Aa][Rr][Tt][\s]{0,} ]] ; then
              # like this.
                RestartServer -w $(echo "${command}" | cut -d " " -f 2 -s | grep '^[0-9]\{1,3\}$')
		            flg=1
		          fi
              # or to separate these commands from Command section is better than that?
              #################################################

	  	        if [[ $command != "" && $flg -eq 0 ]] ; then # if command was not null and not special commands.
                screen -p 0 -S :${session}: -X eval "stuff '${command}
'"
		          fi # in the case command was null, then do nothing.
              sleep 0.1
              status="${com["ComWait"]}"
              ;;
          esac

        done

      elif [[ $sc -eq 0 ]] ; then
        status="${com["ServerNotFound"]}"
      fi
	    ;;
      3) #setting section
        status="${com["SelectValue"]}"
        Setting
      ;;
#	3) # connect server
#      if [ $sc -eq 1 ] ; then #attach screen
#	    screen -r $session
#	  elif [ $sc -eq 0 ] ; then
#	    status="No server found."
#	  fi
#	  ;;
    *) # quit menu
      echo ""
      WriteIniFile
      exit 0
      ;;
esac
}

Main(){
  local c=0
  while true; do
    Draw
    if GetKey 1 ; then
      case "${key}" in
        'left' ) # press right
          col=$(( $col - 1))
          [[ $col -lt 0 ]] && col=0
	        key="wait"
	        status="${com["Default"]}"
          ;;
        'right' ) # press left
          col=$(( $col + 1))
          [[ $col -gt $(( ${#menu[@]} - 1)) ]] && col=$(( ${#menu[@]} - 1))
	        key="wait"
	        status="${com["Default"]}"
          ;;
#    'up' )
    # press up
#    ;;
#    'down' )
    # press down
#    ;;
        'enter' )
	        key="wait"
	        status="${com["Default"]}"
          Execute
          Draw
          ;;
        'esc' )
  	      key="wait"
  	      status="${com["Default"]}"
          ;;
        ' ' )
          key="wait"
          status="${com["Default"]}"
          ;;
          *)
      esac
    fi
    if [[ $(( $c + 1 )) -gt 3 ]] ; then # status clear at 3 times Draw function called
      status="${com["Default"]}"
      c=0
    else
      c=$(( $c + 1 ))
    fi
  done
}

Initialize(){

  cd $dir

  if [[ ! -f $file ]] ; then
    echo "${com["ServerNotFound"]}"
    exit 1
  fi

  clear
  [[ $nologo -eq 0 ]] && Header
  Draw
}

Initialize
Main
