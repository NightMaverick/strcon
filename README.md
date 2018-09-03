Stationeers Bash Console
==========================================

The console for managing a dedicated linux server from the command line.
Commands:

1) status <version|state|players|players_count>

    status - general statistics server: version, status, number of players

    status version - version of the running server

    status state - server status (Joining, Running)

    status players - list of players in a table form

    status players_count - number of players

2) message|notice <text message> - sends a message to all players on the server.

3) start - starting server

4) shutdown <shutdown message> <-t=(time in seconds for shutdown)> - shutdown the server after a specified number of seconds with a specified message

5) stop - immediate server shutdown, kill process

6) update - update server: a) shutdown server after 10 seconds b) run stemcmd.sh for update c) run server
==========================================

Консоль управления выделенным linux сервером из коммандной строки.

Команды:

1) status <version|state|players|players_count>

    status - вывод общей статистики серврера: версия, статус, количество игроков

    status version - вывод версии запущенного сервера

    status state - вывод статуса сервера (Joining, Running)

    status players - вывод списка игроков в виде таблицы

    status players_count - вывод количества игроков

2) message|notice <text message> - отправляет сообщение всем игрокам на сервере.

3) start - запуск сервера

4) shutdown <shutdown message> <-t=(time in seconds for shutdown)> - выключение сервера через указанное количество секунд с указанным сообщением

5) stop - немедленное прекращение процесса сервера.

6) update - обновление сервера: а) остановка сервера через 10 секунд б) Запуск stemcmd.sh для обновления в) Запуск сервера
