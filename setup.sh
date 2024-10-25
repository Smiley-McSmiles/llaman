#!/bin/bash

DIRECTORY=$(cd `dirname $0` && pwd)
llamanVersion=0.1.8
httpPort=8080
defaultUser=open-webui
defaultDir=/opt/open-webui
logFile=$defaultDir/log/llaman.log

source $DIRECTORY/scripts/llaman-functions

Update(){
	HasSudo
	configFile=/opt/open-webui/config/llaman.conf
	source $configFile

	# Conda
	if [[ ! -d $defaultDir/config/conda/open-webui ]]; then
		SetupConda
	fi

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
	packagesNeededRHEL="npm python3-devel make automake gcc gcc-c++ kernel-devel curl screen"
	packagesNeededDebian="npm python3-dev make automake gcc g++ linux-headers-$(uname -r) curl screen"
	packagesNeededArch="npm python-devtools make automake gcc linux-headers curl screen"
	packagesNeededOpenSuse="npm python-devel python312-devel make automake gcc g++ kernel-devel curl screen"
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
	pyVersion="3.11"
	sudo -u $defaultUser bash -c "\
		mkdir -p $defaultDir/miniconda3 $defaultDir/config/conda;\
		wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O $defaultDir/miniconda3/miniconda.sh;\
		chmod +x $defaultDir/miniconda3/miniconda.sh;\
		bash $defaultDir/miniconda3/miniconda.sh -b -u -p $defaultDir/miniconda3;\
		rm $defaultDir/miniconda3/miniconda.sh;\
		source $defaultDir/miniconda3/bin/activate;\
		conda init --all;\
		$defaultDir/miniconda3/bin/conda create --prefix $defaultDir/config/conda/open-webui python=$pyVersion -y;\
		$defaultDir/config/conda/open-webui/bin/pip install -r $defaultDir/open-webui/backend/requirements.txt"
}

Setup(){

	HasSudo
	configFile=$defaultDir/config/llaman.conf
	serviceDirectory=
	ollamaModelsDirectory=/usr/share/ollama/.ollama/models
	
	if PromptUser yN "Would you like to change the default port from 8080?" 0 0 "y/N"; then
		PromptUser num "Enter a valid port" 1001 9999 "$minNumber-$maxNumber"
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

	cd $defaultDir
	git clone https://github.com/open-webui/open-webui.git
	conda $defaultDir/.conda/envs
	cd open-webui/

	cp -RPp .env.example .env

	npm i
	npm run build

	cd backend/
	
	chown -Rf $defaultUser:$defaultUser $defaultDir
	
	sed -ri "s|exec uvicorn|python -m uvicorn|g" start.sh
	sed -ri "s|-8080|-$httpPort|g" start.sh

	chmod -Rf 770 $defaultDir

	SetupConda
	
	systemctl enable --now ollama open-webui llaman-backup.timer
	
	echo "> Ollama and Open-WebUI is now installed"
	echo "> Please visit http://localhost:8080"
	Log "SETUP | Setup finished" $logFile
}

if [[ $1 == "-U" ]]; then
	Update
else
	Setup
fi
