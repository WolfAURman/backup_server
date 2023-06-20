#!/bin/bash

#
#                        _____       _____ 
#                       /  _/ |     / /   |
#                       / / | | /| / / /| |
#                     _/ /  | |/ |/ / ___ |
#                    /___/  |__/|__/_/  |_|
#
#       Created by WolfAURman aka IKrell aka Furry__wolf aka RickAURman
#

DATE=$(date "+%d-%m-%Y.%T") # Не изменять ни в коем случае! Создаёт датацию всех наших будущих файлов, папок и архивов

### Общий раздел настроек ###
USR=root # Заменить на необходимого пользователя
FOLDER=/$USR/Folia/main # Данную переменную вы заменяете на тот путь, который принадлежит рабочей папке сервера, где хранятся папки plugins, world и.т.д
TYPE=docker # На выбор: docker, podman, screen, tmux. В docker и podman в к-ве виртуального терминала используется tmux
CTNAME=folia # Название/id контейнера. При условии если вы используете docker/podman. Если нет - игнорируйте
SNAME=main # Название сессии, замените на своё название сессии виртуального терминала!
HASH=sha256 # Тип хэш суммы файла. На выбор: sha256 или md5

### Раздел с настройками sftp и дальнейшей отправки бекапов ###
SENDING=no # Активна ли передача бекапов на другой сервер при помощи sftp
IP="192.168.0.18" # Указываете свой ip другой машины на которую будут отправлены бекапы
PORT="22" # Указываете порт своей другой машины на которую будут отправлены данные
LOGIN=root # Указываете свой логин (имя пользователя) другой машины на которую будут отправлены бекапы
PASS=pass # Указываете пароль от пользователя машины на которую будут отправлены бекапы
OUT=/root/ # Указываете путь другой машины. Туда, куда будет отправлены все бекапы. Создайте папку если папки не существует!

# Здесь происходит выбор исходя из переменной $TYPE
  case "${TYPE,,}" in 
    # Отправляет команду stop в необходимую сессию, нужному контейнеру
    "docker" ) docker exec -it $CTNAME tmux send -t $SNAME.0 'stop' ENTER ;;
    "podman" ) podman exec -it $CTNAME tmux send -t $SNAME.0 'stop' ENTER ;;
    # `echo -ne '\015'` позволяет эмитировать нажатие кнопки ввод
    "screen" ) screen -S $SNAME -p 0 -X screen "stop"`echo -ne '\015'`       ;;
    # ENTER позволяет эмитировать нажатие кнопки ввод
    "tmux"   ) tmux send -t $SNAME.0 'bc stop' ENTER                         ;;

	esac

# Приостанавливает выполнение следующей команды на N секунд
# Подбирать индивидуально в зависимости от времени выполнения команды stop до полной остановки сервера
sleep 5

# Здесь происходит выбор исходя из переменной $TYPE
  case "${TYPE,,}" in 
    # Отправляет эмуляцию CTRL + C  в необходимую сессию, нужному контейнеру
    "docker" ) docker exec -it $CTNAME tmux send-keys -t $SNAME.0 C-c ;;
    "podman" ) podman exec -it $CTNAME tmux send-keys -t $SNAME.0 C-c ;;
    # Отправляет эмуляцию CTRL + C в необходимую сессию.
    "screen" ) screen -S $SNAME -p 0 -X stuff "^C"                    ;;
    # Отправляет эмуляцию CTRL + C в необходимую сессию. ENTER позволяет эмитировать нажатие кнопки ввод
    "tmux"   ) tmux send-keys -t $SNAME.0 C-c                         ;;

	esac


# Оуществляет поиск папки backup в домашней папке пользователя
if ls /$USR/backup > /dev/null 2>&1

    then
        # Если папка существует, скрипт проходит дальше
        echo "All done" > /dev/null 2>&1

    else
        # Если папки не существует, она создаётся
        mkdir /$USR/backup

fi

# Создание папки которая датируется благодаря переменной $DATE
mkdir /$USR/backup/backup_$DATE

# Осуществляется поиск файла week в /tmp папке.
# Файл week создаётся таймером который запускается еженедельно, для правильной работы еженедельного бекапа
if ls /tmp/week > /dev/null 2>&1

    then
        # Если файл существует, производится еженедельное копирование. В которое входят все миры
        # Если файла не существует, то скрипт продолжает свою обычную работу, и сохраняет то, что используется в обычное время ежедневного бекапа
        cp -R $FOLDER/world $FOLDER/world_nether $FOLDER/world_the_end /$USR/backup/backup_$DATE/
        # Удаление уже не нужного нам файла, который отработал свою функцию, и который будет восстановлен другим демоном снова когда понадобится
        rm -rf /tmp/week

fi

# Копирование папки с плагинами в рабочую папку бекапа, та что датируется временем в переменной $DATE.
cp -R $FOLDER/plugins /$USR/backup/backup_$DATE

# Создаёт бекап всех баз данных, аналогично датирует его благодаря $DATE
mysqldump -u root --all-databases > /$USR/backup/backup_$DATE/all-databases_$DATE.sql

# Здесь происходит выбор исходя из переменной $TYPE
  case "${TYPE,,}" in 
    # Отправляет команду stop в необходимую сессию, нужному контейнеру
    "docker" ) docker exec -it $CTNAME tmux send -t $SNAME.0 'sh start.sh' ENTER ;;
    "podman" ) podman exec -it $CTNAME tmux send -t $SNAME.0 'sh start.sh' ENTER ;;
    # Отправляет команду stop в необходимую сессию. # start.sh заменить на название скрипта запуска.
    # `echo -ne '\015'` позволяет эмитировать нажатие кнопки ввод
    "screen" ) screen -S $SNAME -p 0 -X screen "sh start.sh"`echo -ne '\015'`    ;;
    # Отправляет команду stop в необходимую сессию. ENTER позволяет эмитировать нажатие кнопки ввод
    "tmux"   ) tmux send -t $SNAME.0 'sh start.sh' ENTER                         ;;

	esac

# Создание архива, который всё так же датируется нашей датой из $DATE. Помещается в /$USR/backup
cd /$USR/backup && tar -czf /$USR/backup/backup_$DATE.tar.gz backup_$DATE

# Удаление папки с мусором (Мы уже сделали архив, папка с данными просто будет занимать место в пустую)
rm -rf /$USR/backup/backup_$DATE

# Создание хэш суммы файла в md5
if [$HASH = md5]
  
  then
    md5sum /$USR/backup/backup_$DATE.tar.gz > /$USR/backup/backup_$DATE.md5

fi

# Создание хэш суммы файла в sha256
if [$HASH = sha256]

  then
    sha256sum /$USR/backup/backup_$DATE.tar.gz > /$USR/backup/backup_$DATE.sha256

fi

# Отправка бекапов на удалённую машину по sftp
if [$SENDING = yes]
  
  then
    if [$HASH = md5]
      
      then
        curl --insecure --user $LOGIN:$PASS -T /$USR/backup/backup_$DATE.tar.gz $USR/backup/backup_$DATE.md5 sftp://$IP:$PORT/$OUT
    fi

      if [$HASH = sha256]

        then
          curl --insecure --user $LOGIN:$PASS -T /$USR/backup/backup_$DATE.tar.gz $USR/backup/backup_$DATE.sha256 sftp://$IP:$PORT/$OUT

      fi
fi