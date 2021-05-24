#!/bin/bash

#Script for Postgre Sql Utilities

option=0
currentDate=`date +%Y%m%d`

#Function in order to install Postgre SQL
install_postgre (){

  echo -e "\n Checking if we have Postgre SQL..."
  sleep 3
  verifyInstall=$(which psql)

  if [ $? -eq 0 ]; then
    echo "Postgre has already installed"
  else
    read -s -p " Fill in with the admin pass" adminPass
    read -s -p " Fill in with the pass to postgre SQL " passPostgre
    echo "$adminPass" | sudo -S apt update
    echo "$adminPass" | sudo -S apt-get -y install postgresql postgresql-contrib
    sudo -u postgres psql -C "ALTER USER postgres WITH PASSWORD '{$passPostgre}'"
    echo "$adminPass" | sudo -S systemctl enable postgresql.service
    echo "$adminPass" | sudo -S systemctl start postgresql.service
  fi

  read -n 1 -s -r -p "Click ENTER to continue..."

}

#Function in order to unistall Postgre SQL

unistall_postgre (){

  echo -e "\n Checking if we have Postgre SQL..."
  verifyInstall=$(which psql)

  if [ $? -eq 1 ]; then
    echo "Postgre has not installed yet"

  else
    read -s -p " Fill in with the admin pass" adminPass
    read -e "\n"
    echo "$adminPass" | sudo -S systemctl stop postgresql.service
    echo "$adminPass" | sudo -S apt-get -y --purge remove postgresql\*
    echo "$adminPass" | sudo -S rm -r /etc/postgresql
    echo "$adminPass" | sudo -S rm -r /etc/postgresql-common
    echo "$adminPass" | sudo -S rm -r /var/lib/postgresql
    echo "$adminPass" | sudo -S userdel -r postgres
    echo "$adminPass" | sudo -S groupdel postgresql

  fi

  read -n 1 -s -r -p "Click ENTER to continue..."
}

make_backup(){

  echo "List the databases"
  sudo -u postgres psql -c "\l"
  read -p "Choose the BD for Backup: " dbBackup
  echo -e "\n"

  if [ -d $1 ]; then
    echo "Rights directory.."
    echo "$adminPass" | sudo -S chmod 755 $1
    echo "Making Backup..."
    sudo -u postgres pg_dump -Fc $dbBackup > "$1/dbBackup$currentDate.bak"
    echo "Sucess backup in path: $1/dbBackup$currentDate.bak"
  else
    echo -e "\n The directory $1 doesnt exist"
    echo -e "n"
    read -nl -p "Do you want create the directory $1 (y/n)" responseBD

    if [ responseBD = "y" ]; then
      sudo mkdir $1
      echo "$adminPass" | sudo -S chmod 755 $1
      echo -e "\Making Backup..."
      sleep 3
      sudo -u postgres pg_dump -Fc $dbBackup > "$1/dbBackup$currentDate.bak"
      echo "Sucess backup in path: $1/dbBackup$currentDate.bak"
    else
      echo -e "Exit without Backup.."
      sleep 3
    fi
  fi

  read -n 1 -s -r -p "Click ENTER to continue..."
}

use_backup(){
  read -p "Fill in with the path where is the directory: " directoryBackup

  if [ -d $directoryBackup ]; then
    echo "Listing the files..."
    sleep 3
    ls -la $directoryBackup
    read -p " Fill the file .bak for restore: " restoreBackup

    if [ -f "$directoryBackup/$restoreBackup" ]; then
      read -p "Fill in BD target: " dbTarget
      verifyBD= $(sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -wq $dbTarget)

      if [ $? -eq 0 ]; then
        echo "Restoring in the BD target... $dbTarget"
        sudo -u postgres pg_restore -Fc -d$dbTarget"$directoryBackup/$restoreBackup"
        echo "List databases.."
        sudo -u postgres psql -c "\l"

      else
        echo "The target database dont exist"
        echo " Creating the target database..."
        sleep 4
        sudo -u postgres psql -c "CREATE DATABASE $dbTarget"
        sudo -u postgres pg_restore -Fc -d$dbTarget"$directoryBackup/$restoreBackup"
        echo "List databases..."
        sudo -u postgres psql -c "\l"
      fi

    else
      echo "The file for restore does not exist"
      echo "Verify the file and retry please!"
    fi
      echo "The directory for the backups does not exist"
      echo "Verify the directory and retry please!"
  fi

  read -n 1 -s -r -p "Click ENTER to continue..."
}

list_DB(){
  echo -e "\n Currents databases: "
  sudo -u postgres psql -c "\l"
  read -n 1 -s -r -p "Click ENTER to continue..."
}

while :

do

  clear
  echo"-----------------------------------------------------"
  echo"----------PGUTIL - UTILITIES FOR POSTGRE-------------"
  echo"-----------------------------------------------------"
  echo"--------------------- MAIN --------------------------"
  echo"-----------------------------------------------------"

  echo "1. Install Postgre SQL"
  echo "2. Unistall Postgre SQL"
  echo "3. Make a Back UP"
  echo "4. Use a Back Up"
  echo "5. List the currents databases"
  echo "6. Exist"

  read -n1 -p "Insert one option please: " option

  case $option in
    1) install_postgre
      ;;
    2) unistall_postgre
      ;;
    3) echo -e "\n"
       read -p "Fill in the directory: " directoryBackup
       make_backup $directoryBackup
      ;;
    4) echo -e "\n"
       read -p "Fill in the directory: " directoryBackup
       use_backup $directoryBackup
      ;;
    5) list_DB
      ;;
    6) echo -e "\n Bye bye :)"
       exit 0
      ;;
  esac
done

