#!/bin/bash

default_path="/var/www/html/"
default_email=avea@sfa.fr

msg_no_variable(){
	echo "Veuillez entrer un nom domaine ex: sfa.com"
}

check_exist(){
	 [ -d $default_path$1 ] && echo "le dossier $1 existe." && exit
}

create_folder(){
	echo "création dossiers"
	mkdir -vp $default_path$1/{www,logs}/ >> lamp_log
}

s_mail(){
		echo "$2" | mail -s "user creation $1" $default_email >> lamp_log
}

create_user_pwd(){
	user=$1
	user_pwd=`cat /dev/urandom |base64 -w 0|fold -w 16|head -1`
        read -p "Mot de passe SSH pour $user proposé $user_pwd     , confirmez par y: " -n 1 -r
	echo
	if ! [[ $REPLY =~ ^[!Yy]$ ]]
	then
		create_user_pwd $user
	fi
	echo $user:$user_pwd | chpasswd 
	#s_mail "user SSH 1 sur 2" $user && s_mail "pwd SSH 2 sur 2" $user_pwd
        exit
}

create_user(){
	echo "création user "$1
	useradd -d $default_path$1/ $1
	usermod -a -G apache $1 && usermod -a -G $1 apache #ajout nouvel user dans groupe apache et ajout user apache dans groupe user
	create_user_pwd $1
}

create_apache_conf(){
	sed  's/DOMAINE/'$1'/g' template.conf > $1.conf
}

create_mysql_user_database() {
	DB_NAME=$1
	DB_USER=${1:0:15}
	DB_USER_PASSWD=`cat /dev/urandom |base64 -w 0|fold -w 16|head -1`
        read -p "Mot de passe MYSQL pour $DB_USER proposé $DB_USER_PASSWD     , confirmez par y: " -n 1 -r
        echo
        if ! [[ $REPLY =~ ^[!Yy]$ ]]
        then
                create_mysql_user_database $DB_USER
        fi
       # If /root/.my.cnf exists then it won't ask for root password
       if [ -f /root/.my.cnf ]; then
		mysql_login_param=""
       else
   		read -s -p "Entrez le mot de passe root mysql" rootpasswd
		mysql_login_param="-uroot -p$rootpasswd"
       fi
       		echo
   		mysql $mysql_login_param -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8 COLLATE utf8_general_ci;"
  	        mysql $mysql_login_param -e "CREATE USER \`${DB_USER}\`@localhost IDENTIFIED BY '${DB_USER_PASSWD}';"
		mysql $mysql_login_param -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO \`${DB_USER}\`@localhost;"
		mysql $mysql_login_param -e "FLUSH PRIVILEGES;"
        #s_mail "user MYSQL 1 sur 2" $user && s_mail "pwd MYSQL 2 sur 2" $user_pwd
        exit

}

main(){
	echo "script principal"
	read -p "Création de l'env pour $1, confirmez par y: " -n 1 -r
	echo    # (optional) move to a new line
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
	#	check_exist $1 || create_folder $1 && create_user $1
	#	chown -R $1:apache $default_path$1 
	#	chmod -R 775 $default_path$1 
	#	create_apache_conf $1
		#apachectl configtest && systemctl --type=service | grep -i apache | awk '{print $1}' | cut -d"." -f1 | xargs -I {} service {} reload	
		# lien symbolique adminer.php
		#ln -s $default_path"adminer.php" $default_path$1"/www/"
	
	#	create_mysql_user_database $1
	HOSTNAME=$(hostname)
	./api-rest-ss.sh \"${HOSTNAME^^} MYSQL - $1\" $1 password $1
		exit
	fi
}





[[ ! -z "$1" ]] && main $1 || msg_no_variable
