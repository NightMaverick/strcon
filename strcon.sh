#!/bin/bash
#==========================================
#by Maverick
#anton.maverick@gmail.com
#:
#Webmoney: Z428590895762
#Yandex: 41001672790326
#Bitcoin: 15p12jHb9Vuq9r7yPSt7Xwh2M1aWgBYvZC
#==========================================

#Script config
DEMO="GameVersion : 0.1.1193.5974<br>GameStatus : Running<br>2 Player(s) connected.<br><table><tr><th>display name</th><th>steamId</th><th>score</th><th>playtime</th><th>ping</th></tr><tr><td>Maverick</td><td>22222222222222222</td><td>0</td><td>00:00:03</td><td>2 ms</td></tr><tr><td>Maverick2</td><td>11111111111111111</td><td>1</td><td>01:00:03</td><td>20 ms</td></tr></table>"
USER=steam
STEAMCMD=/home/$USER
GAMEDIR=$STEAMCMD/stationeers

#Server config
SERVER_IP=127.0.0.1 # Server IP (default localhost)
WORLD_TYPE=Mars # Space, Mars, Terrain
AUTOSAVE=300  # Autosave interval in seconds
WORLDNAME=Mars_One # Name for saves
CLEARALLINTERVAL=60
SHUTDOWN_TIME=30
SHUTDOWN_MESSAGE="Server will shutdown in "$SHUTDOWN_TIME" seconds"

#Autoconfig from default.ini
PASSWORD=$(cat $GAMEDIR/default.ini | grep RCONPASSWORD | awk -F"=" '{print $2}')
SERVER_PORT=$(cat $GAMEDIR/default.ini | grep GAMEPORT | awk -F"=" '{print $2}')
SERVER_NAME=$(cat $GAMEDIR/default.ini | grep SERVERNAME | awk -F"=" '{print $2}')
MAP_NAME=$(cat $GAMEDIR/default.ini | grep MAPNAME | awk -F"=" '{print $2}')
MAXPLAYERS=$(cat $GAMEDIR/default.ini | grep MAXPLAYER | awk -F"=" '{print $2}')

TMP=$(mktemp)
/usr/bin/curl --cookie-jar $TMP http://$SERVER_IP:$SERVER_PORT/console/run?command=login%20$PASSWORD > /dev/null 2>&1

function PORT {
 ( exec 3</dev/tcp/$SERVER_IP/$SERVER_PORT ) >/dev/null 2>&1
 if (( $?==0 ))
  then
   PORT_STATUS=1
  else
   PORT_STATUS=0
 fi
 exec 3<&-
}

function GET_STATUS {
 PORT
 if [ "$PORT_STATUS" == "0" ]
  then
   if [ "$1" == "silent" ]
    then
     GAME_STATUS="Stopped"
     return
    else
    echo "Server not started!"
    return
  fi
 fi
 STATUS=$(/usr/bin/curl -s -b $TMP http://$SERVER_IP:$SERVER_PORT/console/run?command=status | sed s/\<br\>/\;/g 2>&1)
 #STATUS=$(echo $DEMO  | sed s/\<br\>/\;/g 2>&1)
 IFS=';' read -r -a STATUS <<< "$STATUS"
 GAME_VERSION=$( echo ${STATUS[0]} | awk -F" : " '{print $2}' )
 GAME_STATUS=$( echo ${STATUS[1]} | awk -F" : " '{print $2}' )
 if [ "${STATUS[2]}" != "No Players" ]
  then
   PLAYERS=$( echo ${STATUS[2]} | awk -F" " '{print $1}' )
  else
   PLAYERS=${STATUS[2]}
 fi
 if [ "$1" == "silent" ]
  then
   return
 fi
 if [ "$1" == "version" ]
  then
   echo $GAME_VERSION
   return
 fi
 if [ "$1" == "state" ]
  then
   echo $GAME_STATUS
   return
 fi
 if [ "$1" == "players" ]
  then
   USERS_LIST
  return
 fi
 if [ "$1" == 'players_count' ]
  then
   if [ "$PLAYERS" == "No Players" ]
    then
     PLAYERS=0
   fi
   echo $PLAYERS
  else
   echo "Server Version: "$GAME_VERSION
   echo "Game Status: "$GAME_STATUS
   echo "Players: "$PLAYERS
 fi
}


function SHUTDOWN {
 GET_STATUS silent
 if [ "$GAME_STATUS" == "Stopped" ]
  then
   echo "Server alredy stoped!"$GAME_STATUS
   return
 fi
 if [ -n "$1" ]
  then
   TEXT=$( echo $1 | awk -F"-t=" '{print $1}')
   TIME=$( echo $1 | awk -F"-t=" '{print $2}')
   if [ -z "$TIME" ]
    then
     TIME=$SHUTDOWN_TIME
   fi
   if [ -z "$TEXT" ]
    then
     TEXT="Server will shutdown in "$TIME" seconds"
   fi
  else
   TIME=$SHUTDOWN_TIME
   TEXT="Server will shutdown in "$TIME" seconds"
 fi
# http://213.132.76.184:27500/console/run?command=shutdown%2520-m%2520%2522asdasd%2520asd%2520asd%2522%2520-t%25205
echo "Server will shutdown in "$TIME" seconds with message: "$TEXT
TEXT=$(echo $TEXT | sed 's/ /%20/g')
/usr/bin/curl -s -b $TMP "http://$SERVER_IP:$SERVER_PORT/console/run?command=shutdown%20-m%20%22$TEXT%22%20-t%20$TIME"
return
}

function KILL {
 GET_STATUS silent
 if [ "$GAME_STATUS" == "Stopped"]
  then
   echo "Server alredy stoped!"
   return
 fi
 PID=$(pidof rocketstation_DedicatedServer.x86_64)
 echo "Emergency stop of the server..."
 /bin/kill -15 $PID
}

function GET_USERS {
if [ -n "${STATUS[3]}" ]
 then
  TABLE=$(echo ${STATUS[3]} | sed s/\<table\>//g | sed s/\<\\/table\>//g | sed s/\<tr\>//g | sed s/\<\\/tr\>/\;/g )
  IFS=';' read -r -a TABLE <<< "$TABLE"
  for (( i = 1; i <= ${#TABLE[@]}-1; i++ )){
   USER_ROW=$(echo ${TABLE[i]} | sed s/\<td\>//g | sed s/\<\\/td\>/\;/g)
   IFS=';' read -r -a USER_ARRAY <<< "$USER_ROW"
   USER_NAME[$(($i-1))]=${USER_ARRAY[0]}
   STEAM_ID[$(($i-1))]=${USER_ARRAY[1]}
   SCORE[$(($i-1))]=${USER_ARRAY[2]}
   PLAY_TIME[$(($i-1))]=${USER_ARRAY[3]}
   PING[$(($i-1))]=$(echo ${USER_ARRAY[4]} | sed s/\ //g)
  }
 else
  TABLE=0
fi
}

function USERS_LIST {
GET_USERS
if [ "$TABLE" == 0 ]
 then
  echo "No Players"
 else
  for i in ${!STEAM_ID[@]}
   do
    TOTAL[$i]=$(($i+1))" "${USER_NAME[i]}" "${STEAM_ID[i]}" "${SCORE[i]}" "${PLAY_TIME[$i]}" "${PING[$i]}
   done
  printf "%s\t| %s\t| %s\t| %s\t| %s\t| %s\n" "#" "User name" "Steam ID" "Score" "Play time" "Ping" "" "" "" "" "" "" ${TOTAL[@]} | column -t -s $'\t'
fi
}



function START {
 GET_STATUS silent
 if [ "$GAME_STATUS" == "Joining" -o "$GAME_STATUS" == "Running" ]
  then
   echo "Server alredy running."
   return
 fi
 ( $GAMEDIR/rocketstation_DedicatedServer.x86_64 -autostart -nographics -batchmode -autosaveinterval=$AUTOSAVE -worldname="$WORLDNAME" -worldtype=$WORLD_TYPE -gameport=$SERVERPORT -clearallinterval=$CLEARALLINTERVAL & ) > /dev/null 2>&1
 ( sleep 1 ) > /dev/null 2>&1
 PID=$(pidof rocketstation_DedicatedServer.x86_64)
 if [ -z "$PID" ]
  then
   echo "Server NOT started!"
   return
  else
   echo "Server starting..."
 fi
 PORT
 while [ "$PORT_STATUS" == "0" ]
  do
   if [ "$с" == "20" ]
    then
     echo "Server NOT started!"
     break
   fi
   PORT
   if (($PORT_STATUS==1))
    then
     echo "Server started."
    else
     c=$c+1
   fi
   sleep 0.5
  done
}

function MESSAGE {
 GET_STATUS silent
  if [ "$GAME_STATUS" == "Stopped" ]
  then
   echo "Server alredy stoped!"
   return
 fi
 if [ "$GAME_STATUS" == "Joining" ]
  then
   echo 'Server waits for players to connect.'
   return
 fi
 if [ -n "$1" ]
  then
   TEXT=$( echo $1 | sed 's/message //g' | sed 's/notice //g')
  else
   echo "Message text need:"
   read TEXT
 fi
 TEXT=$(echo $TEXT | sed 's/ /%20/g' 2>&1)
 /usr/bin/curl -s -b $TMP http://$SERVER_IP:$SERVER_PORT/console/run?command=notice%20%22$TEXT%22
}

function LIST_SAVE {
SAVE_DIR=$(find $GAMEDIR/saves/ -maxdepth 1 -mindepth 1 -type d -printf '%f ')
echo ${SAVE_DIR[1]}
#for i in "${SAVE_DIR[@]}"
# do
# echo $i
#done

}

function SAVE {
 echo $1
 GET_STATUS silent
 if [ "$GAME_STATUS" == "Joining" -o "$GAME_STATUS" == "Running" ]
  then
    if [ -n "$1" ]
     then
      SAVE_NAME=$(echo $1 | sed 's/ /%20/g' 2>&1)
      echo $SAVE_NAME
      /usr/bin/curl -s -b $TMP http://$SERVER_IP:$SERVER_PORT/console/run?command=save%20%22$SAVE_NAME%22
     else
      /usr/bin/curl -s -b $TMP http://$SERVER_IP:$SERVER_PORT/console/run?command=save%20%22$WORLDNAME%22
      read TEXT
    fi
  else
   echo 'Server NOT started!'
 fi

}

function UPDATE {
 GET_STATUS silent
 if [ "$GAME_STATUS" == "Joining" -o "$GAME_STATUS" == "Running" ]
  then
   SHUTDOWN "Server stopping for update in 10 seconds -t=10"
   $( sleep 11 ) /dev/null 2>&1
 fi
 sudo -u $USER $STEAMCMD/steamcmd.sh +login anonymous +force_install_dir $GAMEDIR +app_update 600760 -beta beta validate +quit
 START

}

function CONVERT_TIME {
TIME_UNIX=$(date -d "1/1/1 $(($1/10000000)) sec UTC$(date +"%z")")
}

case $1 in
  status)
    GET_STATUS $2
    ;;
  message|notice)
    TEXT=$(echo $* | sed 's/message//g' | sed 's/notice//g')
    MESSAGE "$TEXT"
    ;;
  start)
    START
    ;;
  shutdown)
    SHUTDOWN_TEXT=$(echo $* | sed 's/shutdown//g')
    SHUTDOWN "$SHUTDOWN_TEXT"
    ;;
  stop)
    KILL
    ;;
  update)
    UPDATE
    ;;
  save)
    SAVE_TEXT=$(echo $* | sed 's/save//g')
    SAVE "$SAVE_TEXT"
    ;;
  list)
    LIST_SAVE
    ;;
  *)
    echo 'status <version|state|players|players_count>'
    echo 'message|notice <text message>'
    echo 'start'
    echo 'shutdown <shutdown message> <-t=(time in seconds for shutdown)>'
    echo 'stop'
    echo 'update'
    echo 'save <save name>'
    exit 1
esac

/usr/bin/rm -rf $TMP
