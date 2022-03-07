#!/bin/bash

elastic=/etc/elasticsearch/elasticsearch.yml
PYTHONPATH=`which python3`
PIPPATH=`which pip3`
PIPElastic=`sudo pip list | grep elasticsearch`
YMLPATH="/etc/elasticsearch/elasticsearch.yml"

check_root(){
  echo ------------------------------------------------------------------
  echo [*] Elasticsearch Forensic
  echo ------------------------------------------------------------------
  echo [*] Checking Priviledge
	if [ $EUID -ne 0 ]; then
		echo [*] Check your Execution Priviledge
		exit
	fi

	echo [*] Priviledge is root
}

check_path(){
  if [ -e ${elastic} ]; then
    display_info
  elif [ -z ${elastic} ]; then
    echo "[*] Searching other path, Elasticsearch Installed on a other Path"
    exit
  else
    echo "[*] Elasticsearch is not installed"
    exit
  fi
}

check_library(){
  if [ -n ${PYTHONPATH} ];  then
    echo "[*] Already installed python3"
  else
    echo "[*] Install the programs that you need to run"
    apt-get install python3
    echo "[*] Installation complete"
  fi

  if [ -n ${PIPPATH} ];  then
    echo "[*] Already installed python3-pip"
  else
    echo "[*] Install the programs that you need to run"
    apt-get install python3-pip
    echo "[*] Installation complete"
  fi

  if [ -n "${PIPElastic}" ];  then
    echo "[*] Already installed Elasticsearch"
  else
    echo "[*] Install the programs that you need to run"
    pip3 install elasticsearch
    pip3 install tabulate[widechars]
    echo "[*] Installation complete"
  fi
}

display_info(){
  echo ------------------------------------------------------------------
  echo [*] Elasticsearch Info
  echo ------------------------------------------------------------------
  cat /etc/elasticsearch/elasticsearch.yml | grep ^"path.data"
  cat /etc/elasticsearch/elasticsearch.yml | grep ^"path.logs"
  cat /etc/elasticsearch/elasticsearch.yml | grep "network.host: [0-9]"
  cat /etc/elasticsearch/elasticsearch.yml | grep "http.port"
  cat /etc/elasticsearch/elasticsearch.yml | grep "dicovery.seed_host"
  cat /etc/elasticsearch/elasticsearch.yml | grep "xpack.security.enable"
  echo ------------------------------------------------------------------
}

acquisition_conf(){
  echo [*] Elasticsearch config Acquisition Start
  mkdir $1/elk_acquisition/config
  cp /etc/elasticsearch/elasticsearch.yml $1/elk_acquisition/config/elasticsearch.yml
  cp /etc/elasticsearch/log4j2.properties $1/elk_acquisition/config/log4j2.properties
  echo [*] Elasticsearch Config Acquisition End
}

acquisition_log(){
  echo [*] Elasticsearch Log Acquisition Start
  cp -r /var/log/elasticsearch/ $1/elk_acquisition/log/
  echo [*] Elasticsearch Log Acquisition End
}

acquisition_p_data(){
  echo [*] Elasticsearch PhysicalData Acquisition Start
  cp -r /var/lib/elasticsearch/ $1/elk_acquisition/data/
  echo [*] Elasticsearch PhysicalData Acquisition End
}

acquisition_data(){
  echo [*] Elasticsearch Data Acquisition Start
  python3 elastic.py --path $1
  echo [*] Elasticsearch Data Acquisition End
}

select_acquisition_option(){
  echo "[*] Output Path Settings"
	read -p "Enter output path [Default path: this path]:" export_path
	echo "[*] Select the Acquisition option you want"
	echo "[#] SELECT Type"
	echo -e "\t[1] All data Acquisition"
	echo -e "\t[2] Log Acquisition"
	echo -e "\t[3] Configuration Acquisition"
	echo -e "\t[4] Physical Data Acquisition(Data Storage File)"
	echo -e "\t[5] Data Acquisition(Identifiable Data, CSV file)"
	echo -e "\t[0] Exit"

	while true
	do
		read -p "Enter the number: " num
		case $num in
			1)
			  mkdir ${export_path:=.}/elk_acquisition
				acquisition_conf ${export_path:=.}
				acquisition_log ${export_path:=.}
				acquisition_data ${export_path:=.}
				acquisition_p_data ${export_path:=.}
				echo -e "[*] Export path: ${export_path:=.}/elk_acquisition"
				echo ------------------------------------------------------------------
				break
				;;
			2)
			  mkdir ${export_path:=.}/elk_acquisition
				acquisition_log ${export_path:=.}
				echo -e "[*] Export path: ${export_path:=.}/log/"
				echo ------------------------------------------------------------------
				break
				;;
			3)
			  mkdir ${export_path:=.}/elk_acquisition
				acquisition_conf ${export_path:=.}
				echo -e "[*] Export path: ${export_path:=.}/config/"
				echo ------------------------------------------------------------------
				break
				;;
      4)
			  mkdir ${export_path:=.}/elk_acquisition
        acquisition_p_data ${export_path:=.}
        echo ------------------------------------------------------------------
        echo -e "[*] Export path: ${export_path:=.}/data/"
        break
        ;;
      5)
			  mkdir ${export_path:=.}/elk_acquisition
        acquisition_data ${export_path:=.}
        echo ------------------------------------------------------------------
        echo -e "[*] Export path: ${export_path:=.}/result/"
        break
        ;;
			*)
				echo [*] Check your input number
				;;
		esac
	done
}

clear

check_root
check_path
check_library
select_acquisition_option