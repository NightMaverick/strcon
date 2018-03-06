#!/bin/bash

#Config
DEMO="GameVersion : 0.1.1193.5974<br>GameStatus : Running<br>2 Player(s) connected.<br><table><tr><th>display name</th><th>steamId</th><th>score</th><th>playtime</th><th>ping</th></tr><tr><td>Maverick</td><td>22222222222222222</td><td>0</td><td>00:00:03</td><td>2 ms</td></tr><tr><td>Maverick2</td><td>11111111111111111</td><td>1</td><td>01:00:03</td><td>20 ms</td></tr></table>"
SERVER_IP=127.0.0.1
SERVER_PORT=27500
PASSWORD=Qwe123qwe

function LOGIN {
TMP=$(mktemp)
/usr/bin/curl --cookie-jar $TMP http://$SERVER_IP:$SERVER_PORT/console/run?command=login%20$PASSWORD > /dev/null 2>&1
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
 LOGIN
 #STATUS=$(/usr/bin/curl -s -b $TMP http://$SERVER_IP:$SERVER_PORT/console/run?command=status | sed s/\<br\>/\;/g 2>&1)
 STATUS=$(echo $DEMO  | sed s/\<br\>/\;/g 2>&1)
 IFS=';' read -r -a STATUS <<< "$STATUS"
 GAME_VERSION=$( echo ${STATUS[0]} | awk -F" : " '{print $2}' )
 GAME_STATUS=$( echo ${STATUS[1]} | awk -F" : " '{print $2}' )
 if [ "${STATUS[2]}" != "No Players" ]
  then
   PLAYERS=$( echo ${STATUS[2]} | awk -F" " '{print $1}' )
  else
   PLAYERS=${STATUS[2]}
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


function CONVERT_TIME {
TIME_UNIX=$(date -d "1/1/1 $(($1/10000000)) sec UTC$(date +"%z")")
}

case $1 in
  status)
    GET_STATUS $2
    ;;
  *)
    echo 'status <version|state|players|players_count>'
    exit 1
esac

/usr/bin/rm -rf $TMP
