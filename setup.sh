#!/bin/bash

DIRECTORY=$(cd `dirname $0` && pwd)
httpPort=8080
defaultUser=open-webui
defaultDir=/opt/open-webui
logFile=$defaultDir/log/llaman.log

source $DIRECTORY/scripts/base_functions.sh

InstallDependencies()
{
	packagesNeededRHEL="npm python3-devel make automake gcc gcc-c++ kernel-devel curl screen"
	packagesNeededDebian="npm python3-dev make automake gcc g++ linux-headers-$(uname -r) screen"
	packagesNeededArch="npm python-devtools make automake gcc linux-headers curl screen"
	packagesNeededOpenSuse="npm python-devel python312-devel make automake gcc g++ kernel-devel curl screen"
	echo "> Preparing to install needed dependancies for Jellyfin..."

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

Setup()
{
	HasSudo
	configFile=$defaultDir/config/llaman.conf
	serviceLocation=
	ollamaModelsDirectory=/usr/share/ollama/.ollama/models
	
	PromptUser dir "Please enter the storage directory for .gguf models" 0 0 "/path/to/directory"
	ggufDirectory=$promptResult
	
	PromptUser dir "Please enter a directory for Open-WebUI backups." 0 0 "/path/to/directory"
	backupDirectory=$promptResult

	echo "Would you like a custom Ollama Model directory?"
	if PromptUser yN "Default Ollama model directory is: /usr/share/ollama/.ollama/models" 0 0 "y/N"; then
		PromptUser dir "Please enter the storage directory for installed Ollama models" 0 0 "/path/to/directory"
		ollamaModelsDirectory=$promptResult
	fi

	InstallDependencies

	if id "$defaultUser" &>/dev/null; then
		userdel $defaultUser
		groupdel $defaultUser
	fi

	if [[ -d $defaultDir ]]; then
		rm -rf $defaultDir
	fi
	
	mkdir $defaultDir
	useradd -rd $defaultDir $defaultUser
	mkdir $defaultDir/config $defaultDir/log
	
	SetVar configFile $configFile "$configFile" str
	SetVar defaultUser $defaultUser "$configFile" str
	SetVar defaultDir $defaultDir "$configFile" str
	SetVar logFile $logFile "$configFile" str
	SetVar httpPort $httpPort "$configFile" str
	SetVar ggufDirectory $ggufDirectory "$configFile" str
	SetVar backupDirectory $backupDirectory "$configFile" str
	SetVar modelFiles $defaultDir/config/modelfiles "$configFile" str
	SetVar ollamaModelsDirectory $ollamaModelsDirectory "$configFile" str
	
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
	elif [ -x "$(command -v firewall-cmd)" ]; then
		Log "SETUP | Using firewalld to unblock $httpPort" $logFile
		firewall-cmd --permanent --add-port=$httpPort/tcp
		firewall-cmd --reload
	fi

	cp -f $DIRECTORY/scripts/llaman /usr/bin/
	cp -f $DIRECTORY/scripts/base_functions.sh /usr/bin/
	cp -rf $DIRECTORY/configs/modelfiles $defaultDir/config/
	chmod +x /usr/bin/llaman
	chmod +x /usr/bin/base_functions.sh

	if [ -d /usr/lib/systemd/system ]; then
		serviceLocation="/usr/lib/systemd/system"
	else
		serviceLocation="/etc/systemd/system"
	fi

	cp -f $DIRECTORY/configs/open-webui.service $serviceLocation/
	SetVar serviceLocation $serviceLocation "$configFile" str
	SetVar User $defaultUser $serviceLocation/open-webui.service str

	cd $defaultDir
	git clone https://github.com/open-webui/open-webui.git
	cd open-webui/

	cp -RPp .env.example .env

	npm i
	npm run build

	cd backend/
	pip install -r requirements.txt -U
	
	chown -Rf $defaultUser:$defaultUser $defaultDir
	
	sed -ri "s|exec uvicorn|python -m uvicorn|g" start.sh

	chmod -Rf 770 $defaultDir
	
	systemctl enable --now ollama open-webui
	
	echo "> Ollama and Open-WebUI is now installed"
	echo "> Please visit http://localhost:8080"
}

Setup