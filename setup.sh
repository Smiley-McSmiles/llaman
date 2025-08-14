#!/bin/bash

DIRECTORY=$(cd `dirname $0` && pwd)
llamanVersion=0.2.5
httpPort=8080
# opendaiPort=8000
defaultUser=open-webui
defaultDir=/opt/open-webui
pipDir=/opt/open-webui/config/conda/open-webui/lib/python3.11/site-packages/open_webui
logFile=$defaultDir/log/llaman.log

source $DIRECTORY/scripts/llaman-functions

Update(){
	HasSudo
	configFile=/opt/open-webui/config/llaman.conf
	source $configFile

	if [[ -d $defaultDIr/open-webui ]]; then
		cp -rf $defaultDir/open-webui/backend/data $pipDir/
		rm -rf $defaultDir/open-webui
		SetupConda
	fi

	if [[ -d $defaultDir/config/conda/opendai ]]; then
		systemctl disable --now opendai.service
		rm -rf $defaultDir/config/conda/opendai
		rm -rf $defaultDir/opendai-speech
		rm -f $serviceDirectory/opendai.service
		Log "SETUP-UPDATE | Removed OpendAI-Speech" $logFile
	fi

	# if [[ ! -d $defaultDir/config/conda/opendai ]]; then
	# 	if PromptUser yN "Would you like to change the default OpendAI port from 8000?" 0 0 "y/N"; then
	# 		PromptUser num "Enter a valid port" 1024 65535 "1024-65535"
	# 		opendaiPort=$promptResult
	# 		echo "> Changing OpendAI port to $opendaiPort"
	# 	else
	# 		echo "> Keeping OpendAI on port 8000..."
	# 	fi
	# 	SetVar opendaiPort $opendaiPort "$configFile" bash int
	# 	SetupTTS
	# 	echo "> Please visit http://localhost:$httpPort"
	# 	echo "> Thee navigate to the Admin Pane/Settings/Audio in Open-WebUI"
	# 	echo "> OpenAI API URL: http://localhost:$opendaiPort/v1"
	# 	echo "> OpenAI API Key: sk-11111111111"
	# fi

	cp -f $DIRECTORY/scripts/llaman /usr/bin/
	cp -f $DIRECTORY/scripts/llaman-functions /usr/bin/
	cp -f $DIRECTORY/scripts/start.sh $defaultDir/
	cp -f $DIRECTORY/configs/open-webui.service $serviceDirectory/
	cp -f $DIRECTORY/configs/modelfiles/* $defaultDir/config/modelfiles/
	cp -f $DIRECTORY/configs/llaman-backup.service $serviceDirectory/
	
	chmod +x $defaultDir/start.sh
	
	if [[ ! -f $serviceDirectory/llaman-backup.timer ]]; then
		cp -f $DIRECTORY/configs/llaman-backup.timer $serviceDirectory/
		SetVar backupDirectory "$backupDirectory" "$configFile" bash directory
		SetVar maxBackupNumber 5 "$configFile" bash int
		SetVar autoBackups true "$configFile" bash bool
		SetVar backupFrequency "weekly" "$configFile" bash string
		systemctl enable --now llaman-backup.timer
		Log "SETUP-UPDATE | SetVar backupDirectory=$backupDirectory" $logFile
		Log "SETUP-UPDATE | SetVar maxBackupNumber=$maxBackupNumer" $logFile
		Log "SETUP-UPDATE | SetVar autoBackups=$true" $logFile
		Log "SETUP-UPDATE | SetVar backupFrequency=weekly" $logFile
	fi
	
	if [ -x "$(command -v apt)" ] || [ -x "$(command -v pacman)" ]; then
		cp $DIRECTORY/llaman.1 /usr/share/man/man1/
	elif [ -x "$(command -v dnf)" ] || [ -x "$(command -v zypper)" ]; then 
		cp $DIRECTORY/llaman.1 /usr/local/share/man/man1/
	fi


	if [[ -f /usr/bin/base_functions.sh ]]; then
		rm -f /usr/bin/base_functions.sh
	fi
	
	systemctl daemon-reload
	echo "> Updated LLaMan to v$llamanVersion!"
	llaman -r
}

InstallDependencies()
{
	packagesNeededRHEL="python3-devel curl screen"
	packagesNeededDebian="python3-dev curl screen"
	packagesNeededArch="python-devtools curl screen"
	packagesNeededOpenSuse="python-devel python312-devel curl screen"
	echo "> Preparing to install needed dependancies for LLaman and Open-WebUI..."

	if [[ -f /etc/os-release ]]; then
		source /etc/os-release
		crbOrPowertools=
		osDetected=true
		echo "> ID=$ID"
		
		if [[ $ID_LIKE == .*"rhel".* ]] || [[ $ID == "rhel" ]]; then
			ID=rhel
			
			if [[ $VERSION_ID == *"."* ]]; then
				VERSION_ID=$(echo $VERSION_ID | cut -d "." -f 1)
			fi
			
			if (( $VERSION_ID < 9 )); then
				crbOrPowertools="powertools"
			else
				crbOrPowertools="crb"
			fi
		fi
		
			case "$ID" in
				fedora)	dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y
								dnf install $packagesNeededRHEL -y ;;
				rhel)			dnf install epel-release -y
								dnf config-manager --set-enabled $crbOrPowertools
								dnf install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-$(rpm -E %rhel).noarch.rpm -y https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-$(rpm -E %rhel).noarch.rpm -y
								dnf install $packagesNeededRHEL -y ;;
				debian)			apt install $packagesNeededDebian -y ;;
				ubuntu)			apt install $packagesNeededDebian -y ;;
				linuxmint)		apt install $packagesNeededDebian -y ;;
				elementary)		apt install $packagesNeededDebian -y ;;
				arch)			pacman -Syu $packagesNeededArch ;;
				endeavouros)	pacman -Syu $packagesNeededArch ;;
				manjaro)		pacman -Syu $packagesNeededArch ;;
				opensuse*)		zypper install $packagesNeededOpenSuse ;;
			esac
	else
		osDetected=false
		echo "+-------------------------------------------------------------------+"
		echo "|                       ******WARNING******                         |"
		echo "|                        ******ERROR******                          |"
		echo "|               FAILED TO FIND /etc/os-release FILE.                |"
		echo "+-------------------------------------------------------------------+"
		
		read -p "Press ENTER to continue" ENTER
	fi
}

SetupConda(){
	echo "> Setting up Conda..."
	pyVersion="3.11"
	sudo chown -Rf $defaultUser:$defaultUser $defaultDir
	sudo -u $defaultUser bash -c "
		mkdir -p $defaultDir/miniconda3 $defaultDir/config/conda
		wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O $defaultDir/miniconda3/miniconda.sh
		chmod +x $defaultDir/miniconda3/miniconda.sh
		bash $defaultDir/miniconda3/miniconda.sh -b -u -p $defaultDir/miniconda3
		rm $defaultDir/miniconda3/miniconda.sh
		source $defaultDir/miniconda3/etc/profile.d/conda.sh
		conda init --all"
	sudo -u $defaultUser bash -c "
		source $defaultDir/miniconda3/etc/profile.d/conda.sh
		conda create --prefix $defaultDir/config/conda/open-webui python=$pyVersion -y
		conda activate $defaultDir/config/conda/open-webui
		pip install open-webui"
	echo "> Finished setting up Conda..."
}

Import() {
	if ! HasSudo; then
		exit
	fi

	if [ -z $1 ]; then
		echo "> ./setup.sh -I requires a path to a llaman-backup.tar file"
		echo ">   For example: sudo ./setup.sh -I /path/to/llaman-backup.tar"
		exit
	fi

	importTar="$1"

	echo "> WARNING!: This procedure will completely erase $defaultDir"
	rm -rf $defaultDir
	echo "> This may take a while..."
	time tar xf "$importTar" -C /

	chmod +x /usr/bin/llaman* $defaultDir/opendai-speech/start-tts.sh $defaultDir/start.sh /usr/bin/llaman /usr/local/bin/ollama
	useradd -rd $defaultDir $defaultUser
	useradd -rd /usr/share/ollama ollama
	chown -Rf $defaultUser:$defaultUser $defaultDir
	chmod -Rf 770 $defaultDir
	chown -Rf ollama:ollama /usr/share/ollama
	systemctl daemon-reload
	systemctl enable --now llaman-backup.service llaman-backup.timer ollama open-webui opendai
	Log "IMPORT | Imported $importTar" $logFile
}


Setup(){

	HasSudo
	configFile=$defaultDir/config/llaman.conf
	serviceDirectory=
	ollamaModelsDirectory=/usr/share/ollama/.ollama/models
	
	if PromptUser yN "Would you like to change the default Open-WebUI port from 8080?" 0 0 "y/N"; then
		PromptUser num "Enter a valid port" 1024 65535 "1024-65535"
		httpPort=$promptResult
		echo "> Changing Open-WebUI port to $httpPort"
	else
		echo "> Keeping Open-WebUI on port 8080..."
	fi
	
	PromptUser dir "Please enter the storage directory for .gguf models" 0 0 "/path/to/directory"
	ggufDirectory=$promptResult
	
	PromptUser dir "Please enter a directory for Open-WebUI backups." 0 0 "/path/to/directory"
	backupDirectory=$promptResult

	PromptUser num "> Please enter your desired maximum number of backup archives" 1 20 "1-20"
	maxBackupNumber=$promptResult

	echo "Would you like a custom Ollama Model directory?"
	if PromptUser yN "Default Ollama model directory is: /usr/share/ollama/.ollama/models" 0 0 "y/N"; then
		PromptUser dir "Please enter the storage directory for installed Ollama models" 0 0 "/path/to/directory"
		ollamaModelsDirectory=$promptResult
	fi

	InstallDependencies

	if id "$defaultUser" &>/dev/null; then
		userdel $defaultUser
		groupdel $defaultUser
		Log "SETUP | Deleted user and group $defaultUser" $logFile
	fi

	if [[ -d $defaultDir ]]; then
		rm -rf $defaultDir
	fi
	
	mkdir $defaultDir
	useradd -rd $defaultDir $defaultUser
	mkdir $defaultDir/config $defaultDir/log
	
	SetVar configFile $configFile "$configFile" bash string
	SetVar defaultUser $defaultUser "$configFile" bash user
	SetVar defaultDir $defaultDir "$configFile" bash directory
	SetVar logFile $logFile "$configFile" bash directory
	SetVar httpPort $httpPort "$configFile" bash int
	SetVar ggufDirectory $ggufDirectory "$configFile" bash directory
	SetVar backupDirectory $backupDirectory "$configFile" bash directory
	SetVar modelFiles $defaultDir/config/modelfiles "$configFile" bash directory
	SetVar ollamaModelsDirectory $ollamaModelsDirectory "$configFile" bash directory
	SetVar maxBackupNumber $maxBackupNumber "$configFile" bash int
	SetVar autoBackups true "$configFile" bash bool
	SetVar backupFrequency "weekly" "$configFile" bash string
	Log "SETUP | SetVar configFile=$configFile" $logFile
	Log "SETUP | SetVar defaultUser=$defaultUser" $logFile
	Log "SETUP | SetVar defaultDir=$defaultDir" $logFile
	Log "SETUP | SetVar httpPort=$httpPort" $logFile
	Log "SETUP | SetVar ggufDirectory=$ggufDirectory" $logFile
	Log "SETUP | SetVar backupDirectory=$backupDirectory" $logFile
	Log "SETUP | SetVar modelFiles=$defaultDir/config/modelfiles" $logFile
	Log "SETUP | SetVar ollamaModelsDirectory=$ollamaModelsDirectory" $logFile
	Log "SETUP | SetVar maxBackupNumber=$maxBackupNumber" $logFile
	Log "SETUP | SetVar autoBackups=true" $logFile
	Log "SETUP | SetVar backupFrequency=weekly" $logFile
	
	curl -fsSL https://ollama.com/install.sh | sh
	
	if [[ ! $ollamaModelsDirectory == /usr/share/ollama/.ollama/models ]]; then
		rm -rf /usr/share/ollama/.ollama/models
		ln -S $ollamaModelsDirectory /usr/share/ollama/.ollama/models
		chown -Rf ollama:ollama /usr/share/ollama/.ollama/models
		chmod -Rf 770 /usr/share/ollama/.ollama/models
	fi
	
	echo "> Unblocking port $httpPort"
	if [ -x "$(command -v ufw)" ]; then
		Log "SETUP | Using ufw to unblock $httpPort" $logFile
		ufw allow $httpPort/tcp
		ufw reload
		Log "SETUP | Used ufw to set port 8080 to allow" $logFile
	elif [ -x "$(command -v firewall-cmd)" ]; then
		Log "SETUP | Using firewalld to unblock $httpPort" $logFile
		firewall-cmd --permanent --add-port=$httpPort/tcp
		firewall-cmd --reload
		Log "SETUP | Used firewallD to set port 8080 to allow" $logFile
	fi
	
	if [ -x "$(command -v apt)" ] || [ -x "$(command -v pacman)" ]; then
		cp $DIRECTORY/llaman.1 /usr/share/man/man1/
	elif [ -x "$(command -v dnf)" ] || [ -x "$(command -v zypper)" ]; then 
		cp $DIRECTORY/llaman.1 /usr/local/share/man/man1/
	fi


	cp -f $DIRECTORY/scripts/llaman /usr/bin/
	cp -f $DIRECTORY/scripts/llaman-functions /usr/bin/
	cp -f $DIRECTORY/scripts/start.sh $defaultDir/
	cp -rf $DIRECTORY/configs/modelfiles $defaultDir/config/
	chmod +x $defaultDir/start.sh
	chmod +x /usr/bin/llaman
	chmod +x /usr/bin/llaman-functions

	if [ -d /usr/lib/systemd/system ]; then
		serviceDirectory="/usr/lib/systemd/system"
	else
		serviceDirectory="/etc/systemd/system"
	fi

	cp -f $DIRECTORY/configs/open-webui.service $serviceDirectory/
	cp -f $DIRECTORY/configs/llaman-backup.service $serviceDirectory/
	cp -f $DIRECTORY/configs/llaman-backup.timer $serviceDirectory/
	SetVar serviceDirectory $serviceDirectory "$configFile" bash directory
	SetVar User $defaultUser $serviceDirectory/open-webui.service bash user
	Log "SETUP | SetVar serviceDirectory=$serviceDirectory" $logFile

	SetupConda
	sed -i 's/os.environ.get("ENABLE_ADMIN_CHAT_ACCESS", "True").lower() == "true"/os.environ.get("ENABLE_ADMIN_CHAT_ACCESS", "True").lower() == "false"/g' $defaultDir/open-webui/backend/open_webui/config.py
	
	chown -Rf $defaultUser:$defaultUser $defaultDir
	chmod -Rf 770 $defaultDir
	
	systemctl enable --now ollama open-webui llaman-backup.timer opendai
	
	echo "-------------------------------------------"
	echo "> Ollama and Open-WebUI is now installed"
	echo "> Please visit http://localhost:$httpPort"
	# echo ">   and navigate to the Audio section in Open-Webui"
	# echo "> OpenAI API URL: http://localhost:$opendaiPort/v1"
	# echo "> OpenAI API Key: sk-11111111111"
	Log "SETUP | Setup finished" $logFile
}

if [[ $1 == "-U" ]]; then
	Update
elif [[ $1 == "-I" ]]; then
	Import "$2"
else
	Setup
fi
