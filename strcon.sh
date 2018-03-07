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
GAMEDIR=/home/steam/stationeers
STEAMCMD=/home/steam

#Server config
SERVER_IP=127.0.0.1 # Server IP (default localhost)
WORLD_TYPE=Mars # Space, Mars, Terrain
AUTOSAVE=300  # Autosave interval in seconds
WORLDNAME=Mars_One # Name for saves
CLEARALLINTERVAL=60

#Autoconfig from default.ini
PASSWORD=$(cat $GAMEDIR/default.ini | grep PASSWORD | awk -F"=" '{print $2}')
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

function START {
 ( /home/steam/stationeers/rocketstation_DedicatedServer.x86_64 -autostart -nographics -batchmode -autosaveinterval=$AUTOSAVE -worldname="$WORLDNAME" -worldtype=$WORLD_TYPE -gameport=$SERVERPORT -clearallinterval=$CLEARALLINTERVAL & ) > /dev/null 2>&1
 ( wait 1 ) > /dev/null 2>&1
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

   sleep 0.5
  done

}

function KILL {
 PID=$(pidof rocketstation_DedicatedServer.x86_64)
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


function GET_STATUS {
 PORT
 if [ "$PORT_STATUS" == "0" ]
  then
   echo "Server not started!"
   return
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

function MESSAGE {
 GET_STATUS silent
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
  stop)
    KILL
    ;;
  port)
    PORT
    echo $PORT_STATUS
    ;;
  *)
    echo 'status <version|state|players|players_count>'\n
    echo 'message|notice <text message>'
    exit 1
esac

/usr/bin/rm -rf $TMP
