#!/bin/bash
version=1.0.0

if [ ! -x "$(command -v unzip)" ] && [ ! -x "$(command -v 7z)" ] && [ ! -x "$(command -v unrar)" ]; then
	echo ">ERROR: Bash Mod Manager requires the following packages:"
	echo ">> unzip, p7zip, p7zip-plugins, unrar"
	exit
fi

configDir=config
configPath=$configDir/bmm.conf
archivesDir=archives
unpackedDir=unpacked
manifestDir=manifest

test ! -d $configDir && mkdir $configDir
test ! -f $configPath && touch $configPath
test ! -d $archivesDir && mkdir $archivesDir
test ! -d $unpackedDir && mkdir $unpackedDir
test ! -d $manifestDir && mkdir $manifestDir

source $configPath
source bmm-functions

#game=("0=STEAM APP ID" "1=INI NAME" "2=My Games NAME" "3=steamapps/common NAME" "4=Script Extender Name")
fallout4=("377160" "Fallout4Custom.ini" "Fallout4" "Fallout 4" "f4se")
fallout3=("22300" "Fallout3Custom.ini" "Fallout3" "Fallout 3" "fose")
fallout3GOTY=("22370" "Fallout3Custom.ini" "Fallout3" "Fallout 3" "fose")
skyrimSE=("110687" "SkyrimCustom.ini" "Skyrim" "Skyrim Special Edition" "skse64")
skyrim=("12248" "SkyrimCustom.ini" "Skyrim" "Skyrim" "skse64")
oblivionGOTY=("22330" "Oblivion.ini" "Oblivion" "Oblivion" "obse")
oblivionGOTYD=("900883" "Oblivion.ini" "Oblivion" "Oblivion" "obse")
gamesList=("${fallout4[3]}" "${fallout3[3]}" "${fallout3GOTY[3]}" "${skyrimSE[3]}" "${skyrim[3]}" "${oblivionGOTY[3]}" "${oblivionGOTYD[3]}")

listOfArchives=$(ls -1 $archivesDir)
listOfMods=$(ls -1 $unpackedDir)

message=""

InstallArchive()
{
	while true
	do
		if [[ ! $(ls -A "$archivesDir/"* 2>/dev/null) ]]; then
			message="> There are no mod archives to install in the $archivesDir folder!
> 1) Please visit https://NexusMods.com to download some.
> 2) Place the archive(s) in the \"$archivesDir\" folder next to bmm.sh.
> 3) Re-run bmm.sh and select option 1 again.
> 4) GAME ON! :)"
			break
		fi
		
		isEsp=false
		listOfArchives=$(ls -1 $archivesDir)
		listOfMods=$(ls -1 $unpackedDir)
		for item in $archivesDir/*
		do
			itemExtension=$(echo "$item" | rev | cut -d "." -f 1 | rev)
			itemNoExtension=$(echo "$item" | sed "s/.$itemExtension//" | sed "s|$archivesDir/||")
			if [[ "$listOfMods" =~ "$itemNoExtension" ]]; then
				listOfArchives=$(echo "$listOfArchives" | sed "s|$itemNoExtension\.$itemExtension|[INSTALLED] $itemNoExtension\.$itemExtension|g")
			fi
		done
		
		
		listOfArchivesBACK="$(echo "$listOfArchives")$(printf "\nBACK")"
		PresentList "$listOfArchivesBACK" "Please enter the number for the archive you want to install."
		if [[ "$presentListResult" == "BACK" ]]; then
			break
		fi
		itemSelected=$(echo "$presentListResult" | sed "s|\[INSTALLED\] ||g")
		echo "Unpacking archive: $itemSelected..."

		archiveExtension=$(echo "$itemSelected" | rev | cut -d "." -f 1 | rev)
		archiveNoExtension=$(echo "$itemSelected" | sed "s|.$archiveExtension||g")
		if [ ! -d "$unpackedDir/$archiveNoExtension" ] && [[ ! $archiveExtension == [Ee][Ss][PpMm] ]]; then
			mkdir "$unpackedDir/$archiveNoExtension"
		elif [[ ! $archiveExtension == [Ee][Ss][PpMm] ]]; then
			rm -rf "$unpackedDir/$archiveNoExtension"
			mkdir "$unpackedDir/$archiveNoExtension"
		fi

		case "$archiveExtension" in
			zip | ZIP)
				unzip -qo "$archivesDir/$itemSelected" -d "$unpackedDir/$archiveNoExtension"
			;;
			7z | 7Z)
				7z -bb1 x "$archivesDir/$itemSelected" -o"$unpackedDir/$archiveNoExtension" > /tmp/nul
			;;
			rar | RAR)
				unrar -idq x "$archivesDir/$itemSelected" -op"$unpackedDir/$archiveNoExtension"
			;;
			esp)
				cp -f "$archivesDir/$itemSelected" "$unpackedDir/$itemSelected"
				isEsp=true
			;;
			*)
				echo "ERROR: Unsupported archive file $itemSelected"
			;;
		esac
		#FixDirCase "$archiveNoExtension"
		if $isEsp; then
			MakeModManifest "$itemSelected"
			EnableMod "$itemSelected"
		else
			MakeModManifest "$archiveNoExtension"
			EnableMod "$archiveNoExtension"
		fi
	done
}

EnableMod()
{
	mod=$1
	
	while true
	do
		if [[ ! $(ls -A "$unpackedDir/"* 2>/dev/null) ]]; then
			message="> There are no mods installed in the $unpackedDir!
>> Please run the 'Install Mod' option"
			break
		fi
		_switch=false
		source "$configPath"
		modEnabled=false
		listOfMods=$(ls -1 $unpackedDir)
		_switch=false
		
		if [[ ! -n $mod ]]; then
			newModList=
			while read line
			do
				_isEnabled=false
				if [[ "$enabledMods" == *"$line"* ]] && [[ ! -n $newModList ]]; then
					_isEnabled=true
					newModList=$(printf "[ENABLED] $line")
				elif [[ "$enabledMods" == *"$line"* ]]; then
					_isEnabled=true
					newModList=$(printf "$newModList\n[ENABLED] $line")
				elif  [[ ! -n $newModList ]]; then
					newModList=$(printf "$line")
				else
					newModList=$(printf "$newModList\n$line")
				fi
			done <<< "$listOfMods"
			newModListBACK=$(echo "$newModList")$(printf "\nBACK")
			PresentList "$newModListBACK" "Please enter the number for the mod you want to enable."
			if [[ "$presentListResult" == "BACK" ]]; then
				break
			fi
			mod="$presentListResult"
			if [[ "$mod" == *"[ENABLED]"* ]]; then
				mod="$(echo $presentListResult | sed "s|\[ENABLED\] ||g")"
				modEnabled=true
			else
				mod="$presentListResult"
			fi
		else
			echo "> Enabling mod $mod..."
			_switch=true
			if [[ "$enabledMods" == *"$mod"* ]]; then
				DisableMod "$mod"
			fi
		fi
		
		manifest="$(cat "$manifestDir/$mod.txt")"
		
		if $modEnabled; then
			echo "This mod is already enabled"
			if ! PromptUser yN "Re-enable anyway?" 0 0 "y/N"; then
				echo "> Exiting..."
				break
			fi
		fi
		echo "> Moving files..."
		while read line
		do
			_source="$(echo $line | cut -d '"' -f 2)"
			_sourceDir=
			_dest="$(echo $line | cut -d '"' -f 4)"
			_destDir=
			if [[ -f "$_source" ]]; then
				_sourceDir="$(echo "$_source" | rev | cut -d "/" -f 2- | rev)"
				_destDir="$(echo "$_dest" | rev | cut -d "/" -f 2- | rev)"
				_file=$(echo "$_dest" | rev | cut -d "/" -f 1 | rev)
				if [[ ! -d "$defaultDir/$_destDir" ]] && [[ ! "$_destDir" =~ "$_file" ]]; then
					mkdir -p "$defaultDir/$_destDir"
					cp -f "$_source" "$defaultDir/$_dest"
	 			else
					cp -f "$_source" "$defaultDir/$_dest"
				fi
			fi
		done <<< "$manifest"
		echo "> Mod enabled!"
		enabledMods+="$mod"
		SetVar enabledMods "$enabledMods" "$configPath" bash string
		if ! $modEnabled; then
			pluginsList=$(echo "$manifest" | grep -oEi " \".*\.es[pm]" | sed 's/ "/*/g' | sed "/.*\/.*/d")
			echo "$pluginsList" >> $pluginsTXT
		fi
		mod=
		if $_switch; then
			break
		fi

	done
}

DisableMod()
{
	while true
	do
		source "$configPath"
		if [[ ! "$enabledMods" =~ [Aa|Ee|Ii|Oo|Uu|Yy] ]]; then
			message="> There are no mods enabled!
>> Please run option 2 to enable some :)"
			break
		fi
		mod=$1
		modList=
		local _switch=false

		if [[ ! -n $mod ]]; then
			for _mod in $unpackedDir/*
			do
				_mod=$(echo "$_mod" | sed "s|$unpackedDir/||g")
	#			echo "$_mod"
	#			echo "$enabledMods"
				if [[ "$enabledMods" == *"$_mod"* ]]; then
					if [[ ! -n $modList ]]; then
						modList=$(printf "$_mod")
					else
						modList=$(printf "$modList\n$_mod")
					fi
				fi
			done
			modListBACK="$(printf "$modList\nBACK")"
			PresentList "$modListBACK" "Please enter the number for the mod you want to disable."
			if [[ "$presentListResult" == "BACK" ]]; then
				break
			fi

			mod="$presentListResult"
		else
			_switch=true
		fi
		
		_manifest=$(cat "$manifestDir/$mod.txt")
		
		echo "> Removing mod files..."
		while read line
		do
			_dest=$(echo "$line" | cut -d '"' -f 4)
			if [[ -f "$defaultDir/$_dest" ]]; then
				rm -f "$defaultDir/$_dest" 
			fi
		done <<< "$_manifest"
		echo "> Cleaning empty directories..."
		find "$defaultDir/"* -type d -empty -delete
		
		enabledMods=$(echo "$enabledMods" | sed "s|$mod||g")
		if [[ ! -n "$enabledMods" ]]; then
			enabledMods=" "
		fi
		SetVar enabledMods "$enabledMods" "$configPath" bash string
		pluginsList=$(echo "$_manifest" | grep -oEi " \".*\.es[pm]" | sed 's/ "//g' | sed "/.*\/.*/d")
		if [[ "$pluginsList" =~ [Aa|Ee|Ii|Oo|Uu|Yy] ]]; then
			while read line
			do
				sed -i "/$line/d" "$pluginsTXT"
				sed -i '/[[:space:]]$^$/d' "$pluginsTXT" && sed -i '/^$/d' "$pluginsTXT"
			done <<< "$pluginsList"
		fi
		echo "> Mod disabled!"
		if $_switch; then
			break
		fi
	done
}

UninstallMod()
{

	while true
	do
		if [[ ! $(ls -A "$manifestDir/"* 2>/dev/null) ]]; then
			message="> There are no mods installed in the $manifestDir!
>> Please run option 1 to install some :)"
			break
		fi
		listOfMods=$(ls -1 $unpackedDir)
		source "$configPath"
		mod=$1
		modList=
		if [[ ! -n $mod ]]; then
			while read _mod
			do
				if [[ ! -n $modList ]]; then
					if [[ "$enabledMods" == *"$_mod"* ]]; then
						modList=$(printf "[ENABLED] $_mod")
					else
						modList=$(printf "$_mod")
					fi
				else
					if [[ "$enabledMods" == *"$_mod"* ]]; then
						modList=$(printf "$modList\n[ENABLED] $_mod")
					else
						modList=$(printf "$modList\n$_mod")
					fi
				fi
			done <<< "$listOfMods"
			modListBACK="$(printf "$modList\nBACK")"

			PresentList "$modListBACK" "Please enter the number for the archive you want to uninstall."
			if [[ "$presentListResult" == "BACK" ]]; then
				break
			fi
			if PromptUser yN "Are you absolutely sure?" 0 0 "y/N"; then
				if [[ "$presentListResult" == *"[ENABLED]"* ]]; then
					mod=$(echo "$presentListResult" | sed "s|\[ENABLED\] ||g")
					echo "Disabling and uninstalling: $mod..."
					DisableMod "$mod"
				else
					mod="$presentListResult"
					echo "Uninstalling: $mod..."
				fi
				rm -rf "$unpackedDir/$mod" "$manifestDir/$mod.txt"
			else
				break
			fi
		fi
		mod=
	done
}

EditPlugins()
{
	# This function was graciously written by ChatGPT 4o
	# Load file into an array
	filename="$pluginsTXT"
	mapfile -t items < "$filename"
	pos=2           # Current cursor position
	selected=-1     # -1 means no line is grabbed

	# Function to print the menu
	print_menu() {
		clear
		for i in "${!items[@]}"; do
		    prefix="  "
		    # Show selection marker
		    [ $i -eq $pos ] && prefix="> "
		    # Show grabbed line indicator
		    [ $i -eq $selected ] && prefix="[*]"
		    printf "%s%s\n" "$prefix" "${items[$i]}"
		done
		
		# Print sticky help line at the bottom
		echo ""
		echo "Controls: ↑/↓ to navigate | Enter to grab/release | 'e' to toggle *Enabled/Disabled | Ctrl+S to save | Ctrl+Q to quit"
	}

	# Function to toggle the '*' prefix
	toggle_star() {
		if [[ "${items[$pos]}" == \** ]]; then
		    items[$pos]="${items[$pos]:1}"
		else
		    items[$pos]="*${items[$pos]}"
		fi
	}

	# Main loop
	print_menu
	while IFS= read -rsn1 key; do
		case "$key" in
		    $'\x1b')  # Handle arrow keys
		        read -rsn2 -t 0.1 arrow
		        case "$arrow" in
		            '[A')  # Up arrow
		                if (( selected == -1 )); then
		                    (( pos > 0 )) && ((pos--))
		                elif (( pos > 0 )); then
		                    # Move selected item up
		                    temp="${items[$pos]}"
		                    items[$pos]="${items[$pos-1]}"
		                    items[$pos-1]="$temp"
		                    ((pos--))
		                fi
		                ;;
		            '[B')  # Down arrow
		                if (( selected == -1 )); then
		                    (( pos < ${#items[@]} - 1 )) && ((pos++))
		                elif (( pos < ${#items[@]} - 1 )); then
		                    # Move selected item down
		                    temp="${items[$pos]}"
		                    items[$pos]="${items[$pos+1]}"
		                    items[$pos+1]="$temp"
		                    ((pos++))
		                fi
		                ;;
		        esac
		        ;;
		    '')  # Enter key
		        if (( selected == -1 )); then
		            # Grab the line
		            selected=$pos
		        else
		            # Drop the line at the current position
		            selected=-1
		        fi
		        ;;
		    'e')  # Toggle '*' prefix on current line
		        toggle_star
		        ;;
		    $'\x13')  # CTRL+S to save and exit
		        > "$filename"
		        for item in "${items[@]}"; do
		            echo "$item" >> "$filename"
		        done
		        break
		        ;;
		    $'\x11')  # CTRL+Q to quit without saving
		        break
		        ;;
		esac
		print_menu
	done
}

ArchiveInvalidation()
{
	source "$configPath"
	activateOrDeactivate=$1
		
	if [[ ! -f $gameCustomINIPath ]]; then
		echo "> ERROR, no $gameNameINI found!"
		gameINIDir=$(echo "$defaultDir" | sed "s|common/.*||g")"compatdata/$appID/pfx/drive_c/users/steamuser/Documents/My Games/$myGamesName"
		gameCustomINIPath="$gameINIDir/$gameNameINI"
#		echo "$gameCustomINIPath"
		SetVar gameCustomINIPath "$gameCustomINIPath" "$configPath" bash string
		exit
	fi

	if [[ $activateOrDeactivate == "deactivate" ]]; then
		if grep -q "bInvalidateOlderFiles=1" "$gameCustomINIPath"; then
			sed -i "/bInvalidateOlderFiles=1/d" "$gameCustomINIPath"
			sed -i "/sResourceDataDirsFinal=/d" "$gameCustomINIPath"
			echo "> Archive Invalidation deactivated!"
		else
			echo "> Archive Invalidation already deactivated!"
		fi
	elif [[ $activateOrDeactivate == "activate" ]]; then
		if grep -q "bInvalidateOlderFiles=1" "$gameCustomINIPath" && grep -q "sResourceDataDirsFinal=" "$gameCustomINIPath"; then
			echo "> Archive Invalidation already activated!"
		else
			if grep -q '[Archive]' "$gameCustomINIPath"; then
				sed -i "s|\[Archive\]|\[Archive\]\nbInvalidateOlderFiles=1\nsResourceDataDirsFinal=|g" "$gameCustomINIPath"
			else
				printf "[Archive]\nbInvalidateOlderFiles=1\nsResourceDataDirsFinal=" >> "$gameCustomINIPath"
			fi
			echo "> Archive Invalidation Activated!"
		fi
	fi
}

ScriptExtender()
{
	source "$configPath"
	switch=$1
	gamePath=$(echo "$defaultDir" | sed "s|/[Dd]ata.*||g")
	scriptExtenderEXE="$scriptExtender""_loader.exe"
	scriptExtenderPath="$gamePath/$scriptExtenderEXE"
	launcherPath="$gamePath/$myGamesName""Launcher.exe"
	if [[ ! -f "$scriptExtenderPath" ]]; then
		echo "> ERROR: No $scriptExtenderEXE found in $gameName2 directory!"
		exit
	fi

	case "$switch" in
		activate)
			if [[ ! -f "$launcherPath.bak" ]]; then
				mv -f "$launcherPath" "$launcherPath.bak"
				cp -f "$scriptExtenderPath" "$launcherPath"
			else
				echo "> $scriptExtender already activated!"
			fi
		;;
		deactivate)
			if [[ -f "$launcherPath.bak" ]]; then
				rm -f "$launcherPath"
				mv -f "$launcherPath.bak" "$launcherPath"
			else
				echo "> $scriptExtender already deactivated!"
			fi
		;;
		*)
			echo "> ERROR: function ScriptExtender() requires either \"activate\" or \"deactivate\" when called!"
		;;
	esac
}

FixDirCase()
{
	mod="$1"
	dirManifest=$(tree --noreport -dif "$unpackedDir/$mod" | sed "s|$unpackedDir/$mod||g" | tac | cut -d "/" -f 2-)
#	echo "$dirManifest"
	
	echo "$dirManifest" | while read dir 
	do
	   # do something with $line here
		rootDir=
		dirFixed=
		if [[ "$dir" =~ "/" ]]; then
			rootDir=$(echo $dir | rev | cut -d "/" -f 2- | rev)
			dirFixed=$(echo $dir | rev | cut -d "/" -f 1 | rev | sed -e "s/\b\(.\)/\u\1/g")
#			echo "rootDir=$rootDir"
#			echo "dirFixed=$dirFixed"
			dirFixed="$rootDir"/"$dirFixed"
		else
			rootDir=$(echo $dir | rev | cut -d "/" -f 2- | rev | sed -e "s/\b\(.\)/\u\1/g")
			dirFixed="$rootDir"
#			echo "rootDir=$rootDir"
#			echo "dirFixed=$rootDir"
		fi
		mv -f "$unpackedDir/$mod/$dir" "$unpackedDir/$mod/$dirFixed" 2>/dev/null
#		echo "mv -f \"$unpackedDir/$mod/$dir\" \"$unpackedDir/$mod/$dirFixed\""
	done
	
	manifest=$(tree --noreport -if $unpackedDir/"$mod" | sed "s|$unpackedDir/$mod||g")
	# echo "$manifest" > "$manifestDir/$mod.txt"
}

MakeModManifest()
{
	mod=$1
	requiredInstallFilesBegin=
	requiredInstallFilesEnd=
	requiredInstallFileSources=()
	requiredInstallFileDests=()
	requiredInstallFolderSources=()
	requiredInstallFolderDests=()
	optionalFileSources=()
	optionalFileDests=()
	optionalFolderSources=()
	optionalFolderDests=()
	groupBegin=()
	groupEnd=()
	groupNames=()
	groupTypes=()
	flagsEnabled=()
	pluginBegin=()
	pluginNames=()
	pluginEnd=()
	patternBegin=()
	patternEnd=()
	iteration=0
	lineNumber=0
	fomodXML=
	if [ -f "$unpackedDir/$mod" ]; then
		echo "Making manifest..."
		manifest="\"$unpackedDir/$mod\" \"$mod\""
		if [ -f "$manifestDir/$mod.txt" ];then
			rm -f "$manifestDir/$mod.txt"
		fi
		echo "$manifest" > "$manifestDir/$mod.txt"
	else
		fomodXML=$(tree -i -f "$unpackedDir/$mod/" | grep -i "ModuleConfig.xml")
	fi
	IFS=' '
	
	if [ ! -f "$fomodXML" ] && [ ! -f "$unpackedDir/$mod" ]; then
		echo "> No FOMod folder detected!"
#		FixDirCase "$mod"
#		cp -rf "$unpackedDir/$mod/"* $defaultDir/
		if [ -f "$manifestDir/$mod.txt" ];then
			rm -f "$manifestDir/$mod.txt"
		fi
		manifest=$(tree --noreport -if $unpackedDir/"$mod")
		removedLine=$(echo "$manifest" | grep -Eio ".*\.esp|.*\.esm|.*\.ba2|.*\.cdx|.*/meshes/|.*/materials/|.*/textures/|.*/sound/|.*/scripts/|.*/interface/|.*/tools/|.*/video/" | head -n 1)
		if [[ -f "$removedLine" ]]; then
			removedLine=$(echo "$removedLine" | rev | cut -d "/" -f 2- | rev | head -n 1)$(printf "/")
		else
			removedLine=$(echo "$removedLine" | rev | cut -d "/" -f 3- | rev | head -n 1)$(printf "/")
		fi
#		echo "$removedLine" #debug
		IFS=$'\n'
		for _line in $manifest
		do
			_dest=
			if [[ ! "$removedLine" == *"/"* ]]; then
				if [[ -d "$_line" ]]; then
					_dest="$(echo "$_line" | sed "s|$unpackedDir/$mod/||g" | sed 's/\(\/\|^\)\(.\)/\1\u\2/g')"
				elif [[ -f "$_line" ]]; then
					_dest="$(echo "$_line" | sed "s|$unpackedDir/$mod/||g" | sed 's|\([^/]*\)/|\u\1/|g')"
				fi
			else
				if [[ -d "$_line" ]]; then
					_dest="$(echo "$_line" | sed "s|$removedLine||g" | sed 's/\(\/\|^\)\(.\)/\1\u\2/g')"
				elif [[ -f "$_line" ]]; then
					_dest="$(echo "$_line" | sed "s|$removedLine||g" | sed 's|\([^/]*\)/|\u\1/|g')"
				fi
			fi
			_newLine="\"$_line\" \"$_dest\""
#				echo "> $_newLine"
			echo "$_newLine" >> "$manifestDir/$mod.txt"
		done
				
	elif [ ! -f "$unpackedDir/$mod" ]; then
		echo "> FOMod folder detected!"
		formattedFomod=$(cat "$fomodXML" | sed "s|\\\|/|g" | sed "s|\"/|\"|g" | sed "s| /||g" | sed 's/!\[CDATA\[//g' | sed 's/\]\]//g')
#		echo "$formattedFomod"
		IFS=$'\n'
		for line in $formattedFomod
		do
			lineNumber=$(bc <<< "$lineNumber+1")
			lineTag=$(echo "$line" | cut -d '=' -f 1)
			newLine=$(echo "$line" | cut -d '=' -f 2-)
			if [[ "$line" =~ [Aa|Ee|Ii|Oo|Uu|Yy] ]]; then
				case "$line" in
				*"<requiredInstallFiles>"*)
					requiredInstallFilesBegin=$lineNumber
				;;
				*"</requiredInstallFiles>"*)
					requiredInstallFilesEnd=$lineNumber
					_requiredFilesLines=$(bc <<< "$requiredInstallFilesEnd-$requiredInstallFilesBegin")
					_requiredFiles="$(echo "$formattedFomod" | head -n $requiredInstallFilesEnd | tail -n $_requiredFilesLines)"
					IFS=$'\n'
					for _line in $_requiredFiles
					do
						case "$_line" in
							*"<file source"*)
								requiredInstallFileSources+=($(echo "$_line" | cut -d '"' -f 2))
								_dest=$(echo "$_line" | cut -d '"' -f 4 | sed 's|\([^/]*\)/|\u\1/|g')
								if [[ "$_dest" =~ [Aa|Ee|Ii|Oo|Uu] ]]; then
									requiredInstallFileDests+=($_dest)
								else
									_dest=$(echo '$defaultDir')
									requiredInstallFileDests+=($_dest)
								fi
							;;
							*"<folder source"*)
								requiredInstallFolderSources+=($(echo "$_line" | cut -d '"' -f 2))
								_dest=$(echo "$_line" | cut -d '"' -f 4 | sed 's/\(\/\|^\)\(.\)/\1\u\2/g')
								if [[ "$_dest" =~ [Aa|Ee|Ii|Oo|Uu] ]]; then
									requiredInstallFolderDests+=($_dest)
								else
									_dest=$(echo '$defaultDir')
									requiredInstallFolderDests+=($_dest)
								fi
							;;
						esac
					done
				;;
				*"<group name"*)
					groupBegin+=($lineNumber)
					_groupName=$(echo "$line" | cut -d '"' -f 2)
					groupNames+=($_groupName)
					_groupType=$(echo "$line" | cut -d '"' -f 4)
					groupTypes+=($_groupType)
				;;
				*"</group>"*)
					groupEnd+=($lineNumber)
				;;
				*"<pattern>"*)
					patternBegin+=($lineNumber)
				;;
				*"</pattern>"*)
					patternEnd+=($lineNumber)
				;;
				esac
			fi
		done
		
		for _lineNumber in "${groupBegin[@]}"
		do
			_lineNumberEnd=${groupEnd[$iteration]}
			_lines=$(bc <<< "$_lineNumberEnd-$_lineNumber")
			_group="$(echo "$formattedFomod" | head -n $_lineNumberEnd | tail -n $_lines)"
#			echo "iteration=$iteration"
#			echo "_lineNumber=$_lineNumber"
#			echo "_lineNumberEnd=$_lineNumberEnd"
#			echo "_lines=$_lines"
#			echo "_group=$_group"
			_pluginNameCurrent=""
			_pluginFlagCurrent=""
			_descriptionCurrent=""
			_pluginNames=()
			_pluginFlags=()
			_folderSources=()
			_folderDests=()
			_fileSources=()
			_fileDests=()
			_selectOneSwitch=false
			_descriptionSwitch=false

			IFS=$'\n'
			for line in $_group
			do
				if [[ "${groupTypes[$iteration]}" == "SelectAny" ]]; then
					case "$line" in
						*"<plugin name"*)
							_folderSources=()
							_folderDests=()
							_fileSources=()
							_fileDests=()
							_pluginFlags=()
							_pluginNameCurrent=$(echo "$line" | cut -d '"' -f 2)
						;;
						*"<flag"*)
							_pluginFlags+=($(echo "$line" | cut -d '"' -f 2))
							_pluginFlagCurrent=$(echo "$line" | cut -d '"' -f 2)
						;;
						*"<folder source"*)
							_folderSources+=($(echo "$line" | cut -d '"' -f 2))
							_dest=$(echo "$line" | cut -d '"' -f 4 | sed 's/\(\/\|^\)\(.\)/\1\u\2/g')
							if [[ $_dest =~ [Aa|Ee|Ii|Oo|Uu] ]]; then
								_folderDests+=($_dest)
							else
								_dest=$(echo '$defaultDir')
								_folderDests+=($_dest)
#								echo "Adding file _dest=$_dest" #debug
							fi
						;;
						*"<file source"*)
							_fileSources+=($(echo "$line" | cut -d '"' -f 2))
							_dest=$(echo "$line" | cut -d '"' -f 4 | sed 's|\([^/]*\)/|\u\1/|g')
							if [[ $_dest =~ [Aa|Ee|Ii|Oo|Uu] ]]; then
								_fileDests+=($_dest)
#								echo "Adding file _dest=$_dest" #debug
							else
								_dest=$(echo '$defaultDir')
								_fileDests+=($_dest)
#								echo "Adding file _dest=$_dest" #debug
							fi
						;;
						*"</plugin>"*)
							echo "$_descriptionCurrent"
							if PromptUser Yn "Install plugin $_pluginNameCurrent?" 0 0 "Y/n"; then
								echo "> Installing $_pluginNameCurrent..."
								for folder in "${_folderSources[@]}"
								do
									optionalFolderSources+=($folder)
								done

								for folder in "${_folderDests[@]}"
								do
									optionalFolderDests+=($folder)
								done
								
								for file in "${_fileSources[@]}"
								do
									optionalFileSources+=($file)
								done

								for file in "${_fileDests[@]}"
								do
									optionalFileDests+=($file)
								done
								
								for flag in "${_pluginFlags[@]}"
								do
									flagsEnabled+=($flag)
								done
								IFS=$'\n'
							else
								echo "> Skipping ${_pluginName[0]}"
							fi
							_descriptionCurrent=""
						;;
						*"<description"*)
							if [[ "$line" == *"</description>"* ]] || [[ "$line" == *"/>"* ]]; then
								_descriptionCurrent+=$(echo "$line" | sed "s|<description>||g" | sed "s|</description>||g" | sed "s|<.*||g"| sed 's/&#xD;//g' | sed "s|  ||g" | sed "s|\t||g")
							else
								_descriptionSwitch=true
							fi
						;;
						*"</description")
							_descriptionSwitch=false
						;;
						*)
							if $_descriptionSwitch; then
								_descriptionCurrent+=$(echo "$line" | sed "s|<description>||g" | sed "s|</description>||g" | sed "s|<.*||g"| sed 's/&#xD;//g' | sed "s|  ||g" | sed "s|\t||g")
							fi
						;;
					esac
				elif [[ ${groupTypes[$iteration]} == "SelectExactlyOne" ]] || [[ ${groupTypes[$iteration]} == "SelectAtMostOne" ]] && ! $_selectOneSwitch ; then
					case "$line" in
						*"<plugin name"*)
							_name=$(echo "$line" | cut -d '"' -f 2)
#							echo "<plugin name=$_name" #debug
							_pluginNames+=("'$_name'")
							_pluginNameCurrent="$_name"
						;;
						*"<flag"*)
							_pluginFlags+=("$_pluginNameCurrent:"$(echo "$line" | cut -d '"' -f 2))
						;;
						*"<folder source"*)
							_folderSources+=("$_pluginNameCurrent:"$(echo "$line" | cut -d '"' -f 2))
							_dest="$_pluginNameCurrent:"$(echo "$line" | cut -d '"' -f 4)
							if [[ $_dest =~ [Aa|Ee|Ii|Oo|Uu] ]]; then
								_folderDests+=($_dest)
							else
								_dest="$_pluginNameCurrent:"'$defaultDir'
								_folderDests+=($_dest)
							fi
						;;
						*"<file source"*)
							_fileSources+=("$_pluginNameCurrent:"$(echo "$line" | cut -d '"' -f 2))
							_dest="$_pluginNameCurrent:"$(echo "$line" | cut -d '"' -f 4)
#							echo "$_dest" #debug
							if [[ $_dest =~ [Aa|Ee|Ii|Oo|Uu] ]]; then
								_fileDests+=($_dest)
#								echo "${_fileDests[@]}" #debug
							else
								_dest="$_pluginNameCurrent:"'$defaultDir'
								_fileDests+=($_dest)
#								echo "${_fileDests[@]}" #debug
							fi
						;;
						*"</plugins>"*)
							_pluginNamesList=""
							for item in "${_pluginNames[@]}"
							do
								if [[ "$_pluginNamesList" =~ [Aa|Ee|Ii|Oo|Uu|Yy|1-9] ]]; then
									_pluginNamesList=$(printf "$_pluginNamesList\n$item")
								else
									_pluginNamesList=$(printf "$item")
								fi
							done
							
							if [[ ${groupTypes[$iteration]} == "SelectAtMostOne" ]]; then
								if [[ "$_pluginNamesList" =~ [Aa|Ee|Ii|Oo|Uu|Yy|1-9] ]]; then
									_pluginNamesList=$(printf "$_pluginNamesList\nNone")
								else
									_pluginNamesList=$(printf "$item")
								fi
							fi
							echo "$_descriptionCurrent"
#							echo "$_pluginNamesList" #debug
							PresentList "$_pluginNamesList" "Please enter the number for the plugin you want to install."
							_itemSelected=$presentListResult
							
							if [[ "$_itemSelected" == "None" ]]; then
								echo "> Skipping..."
							else
								for flag in "${_pluginFlags[@]}"
								do
									if [[ "$flag" =~ "$_itemSelected" ]]; then
										flag=$(echo "$flag" | sed "s|$_itemSelected:||g")
										flagsEnabled+=($flag)
									fi
								done
								
								for folder in "${_folderSources[@]}"
								do
									if [[ "$folder" =~ "$_itemSelected" ]]; then
										folder=$(echo "$folder" | sed "s|$_itemSelected:||g")
										optionalFolderSources+=($folder)
									fi
								done
								
								for folder in "${_folderDests[@]}"
								do
									if [[ "$folder" =~ "$_itemSelected" ]]; then
										folder=$(echo "$folder" | sed "s|$_itemSelected:||g" | sed 's/\(\/\|^\)\(.\)/\1\u\2/g')
										optionalFolderDests+=($folder)
#										echo "adding folder $folder" #debug
									fi
								done
								
								for file in "${_fileSources[@]}"
								do
									_itemSelected2=$(echo "$_itemSelected" | sed "s|'||g")
									if [[ "$file" == *$_itemSelected2* ]]; then
										file=$(echo "$file" | cut -d ":" -f 2)
										optionalFileSources+=($file)
#										echo "adding source file: $file" #debug
									fi
								done
								
								for file in "${_fileDests[@]}"
								do
									_itemSelected2=$(echo "$_itemSelected" | sed "s|'||g")
#									echo "file = $file" #debug
#									echo "_itemSelected2 = $_itemSelected2" #debug
									if [[ "$file" == *$_itemSelected2* ]]; then
										file=$(echo "$file" | cut -d ":" -f 2 | sed 's|\([^/]*\)/|\u\1/|g')
										optionalFileDests+=($file)
#										echo "adding destination file: $file" #debug
									fi
								done
							fi
							_descriptionCurrent=""
						;;
						*"<description"*)
							if [[ "$line" == *"</description>"* ]] || [[ "$line" == *"/>"* ]]; then
								_descriptionCurrent+=$(echo "$line" | sed "s|<description>||g" | sed "s|</description>||g" | sed "s|<.*||g"| sed 's/&#xD;//g' | sed "s|  ||g" | sed "s|\t||g")
							else
								_descriptionSwitch=true
							fi
						;;
						*"</description")
							_descriptionSwitch=false
						;;
						*)
							if $_descriptionSwitch; then
								_descriptionCurrent+=$(echo "$line" | sed "s|<description>||g" | sed "s|</description>||g" | sed "s|<.*||g"| sed 's/&#xD;//g' | sed "s|  ||g" | sed "s|\t||g")
							fi
						;;
					esac
				fi

			done
			
			iteration=$(bc <<< "$iteration+1")
		done
		
		_iteration=0
		for _lineNumber in "${patternBegin[@]}"
		do
			_lineNumberEnd=${patternEnd[$_iteration]}
			_lines=$(bc <<< "$_lineNumberEnd-$_lineNumber")
			_pattern="$(echo "$formattedFomod" | head -n $_lineNumberEnd | tail -n $_lines)"
			_flags=()
			_flagValues=()
			_folderSources=()
			_folderDests=()
			_fileSources=()
			_fileDests=()
			_triggers=()
			_patternIteration=0
			IFS=$'\n'
			for _line in $_pattern
			do
				case "$_line" in
					*"<flagDependency"*)
						_flag=$(echo $_line | cut -d '"' -f 2)
						_flagValue=$(echo $_line | cut -d '"' -f 4)
						_flags+=($_flag)
						_flagValues+=($_flagValue)
					;;
					*"folder source"*)
						_folderSource=$(echo $_line | cut -d '"' -f 2)
						_folderDest=$(echo $_line | cut -d '"' -f 4 | sed 's/\(\/\|^\)\(.\)/\1\u\2/g')
						_folderSources+=($_folderSource)
						_dest="$_folderDest"
						if [[ "$_dest" =~ [Aa|Ee|Ii|Oo|Uu] ]]; then
							_folderDests+=($_dest)
#							echo "adding folder $_dest"
						else
							_dest=$(echo '$defaultDir')
							_folderDests+=($_dest)
#							echo "adding folder $_dest"
						fi
					;;
					*"file source"*)
						_fileSource=$(echo $_line | cut -d '"' -f 2)
						_fileDest=$(echo $_line | cut -d '"' -f 4 | sed 's|\([^/]*\)/|\u\1/|g')
						_fileSources+=($_fileSource)
						_dest="$_fileDest"
						if [[ "$_dest" =~ [Aa|Ee|Ii|Oo|Uu] ]]; then
							_fileDests+=($_dest)
#							echo "adding file $_dest"
						else
							_dest=$(echo '$defaultDir')
							_fileDests+=($_dest)
#							echo "adding file $_dest"
						fi
					;;
				esac
			done
			
			for _flag in "${_flags[@]}"
			do
				_pass=false
				
				for _flagEnabled in "${flagsEnabled[@]}"
				do
					if [[ "$_flagEnabled" == "$_flag" ]] && [[ "${_flagValues[$_patternIteration]}" == "On" ]]; then
#						printf "Pass | flagEnabled | _flag | Value = \"$_flagEnabled\" | \"$_flag\" | ${_flagValues[$_patternIteration]}\n"
						_pass=true
#					else
#						printf "Fail | flagEnabled | _flag | Value = \"$_flagEnabled\" | \"$_flag\" | ${_flagValues[$_patternIteration]}\n"
					fi
				done

				_patternIteration=$(bc <<< "$_patternIteration+1")
				
				if $_pass; then
					_triggers+=("pass")
				else
					_triggers+=("fail")
				fi
			done

			if [[ ! "${_triggers[@]}" =~ "fail" ]]; then
#				echo "> Skipping pattern..."
#				echo "${_triggers[@]}"
#			else
#				echo "> Adding pattern..."
				for _folder in "${_folderSources[@]}"
				do
					optionalFolderSources+=($_folder)
				done

				for _folder in "${_folderDests[@]}"
				do
					optionalFolderDests+=($_folder)
				done

				for _file in "${_fileSources[@]}"
				do
					optionalFileSources+=($_file)
				done

				for _file in "${_fileDests[@]}"
				do
					optionalFileDests+=($_file)
				done
			fi
		done
		_triggers=()
		_iteration=$(bc <<< "$_iteration+1")

#		echo "requiredInstallFileSources=" #debug
#		echo ${requiredInstallFileSources[@]} #debug
#		echo "requiredInstallFileDests=" #debug
#		echo ${requiredInstallFileDests[@]} #debug
#		echo "requiredInstallFolderSources=" #debug
#		echo ${requiredInstallFolderSources[@]} #debug
#		echo "requiredInstallFolderDests=" #debug
#		echo ${requiredInstallFolderDests[@]} #debug

#		echo "optionalFileSources=" #debug
#		echo ${optionalFileSources[@]} #debug
#		echo "optionalFileDests=" #debug
#		echo ${optionalFileDests[@]} #debug
#		echo "optionalFolderSources=" #debug
#		echo ${optionalFolderSources[@]} #debug
#		echo "optionalFolderDests=" #debug
#		echo ${optionalFolderDests[@]} #debug
	
#		echo "flagsEnabled=" #debug
#		echo ${flagsEnabled[@]} #debug
		
#		echo "groupBegin=" #debug
#		echo ${groupBegin[@]} #debug
#		echo "groupEnd=" #debug
#		echo ${groupEnd[@]} #debug
#		echo "groupNames=" #debug
#		echo ${groupNames[@]} #debug
#		echo "groupTypes=" #debug
#		echo ${groupTypes[@]} #debug
#		echo "patternBegin=" #debug
#		echo ${patternBegin[@]} #debug
#		echo "patternEnd=" #debug
#		echo ${patternEnd[@]} #debug

		if [ -f "$manifestDir/$mod.txt" ];then
			rm -f "$manifestDir/$mod.txt"
		fi
		
		echo "> Making manifest..."
		
		_iteration=0
		for _item in "${requiredInstallFileSources[@]}"
		do
			echo "\"$unpackedDir/$mod/$_item\" \"${requiredInstallFileDests[$_iteration]}\"" >> "$manifestDir/$mod.txt"
			_iteration=$(bc <<< "$_iteration+1")
		done
		_iteration=0
		for _item in "${requiredInstallFolderSources[@]}"
		do
			_manifest=$(tree --noreport -Qif "$unpackedDir/$mod/$_item")
			IFS=$'\n'
			for _line in $_manifest
			do
				if [[ ! "$_line" == "\"$unpackedDir/$mod/$_item\"" ]]; then
					_dest="$(echo $_line | sed "s|$unpackedDir/$mod/$_item/|/${requiredInstallFolderDests[$_iteration]}/|g" | sed 's/$defaultDir//g'| sed 's/\(\/\|^\)\(.\)/\1\u\2/g' | cut -d "/" -f 2-)"
					_firstDestChar=$(echo "$_dest" | cut -c 1)
					if [[ $_firstDestChar == "/" ]]; then
						_dest=$(echo "$_dest" | cut -c 2- | sed 's/\(^.\)/\u\1/g')
					fi
					_newLine="$_line \"$_dest"
#					echo "> $_newLine"
					echo "$_newLine" >> "$manifestDir/$mod.txt"
				fi
			done
			_iteration=$(bc <<< "$_iteration+1")
		done
		_iteration=0
		for _item in "${optionalFileSources[@]}"
		do
			echo "\"$unpackedDir/$mod/$_item\" \"${optionalFileDests[$_iteration]}\"" >> "$manifestDir/$mod.txt"
			_iteration=$(bc <<< "$_iteration+1")
			echo "OptionalFileSources/Dests=\"$unpackedDir/$mod/$_item\" \"${optionalFileDests[$_iteration]}\"" #Debug
		done
		_iteration=0
		for _item in "${optionalFolderSources[@]}"
		do
			_manifest=$(tree --noreport -Qif "$unpackedDir/$mod/$_item")
			IFS=$'\n'
			for _line in $_manifest
			do
				if [[ ! "$_line" == *"$_item\"" ]] && [[ ! "$_line" == *"$_item/\"" ]]; then # If item doesn't equal base folder then
					_dest="$(echo "$_line" | sed "s|.*$_item|${optionalFolderDests[$_iteration]}/|g" | sed 's/$defaultDir//g'| sed 's/\(\/\|^\)\(.\)/\1\u\2/g' | sed "s|//|/|g")" # | cut -d "/" -f 2-)"
					_firstDestChar=$(echo "$_dest" | cut -c 1)
					if [[ $_firstDestChar == "/" ]]; then
						_dest=$(echo "$_dest" | cut -c 2- | sed 's/\(^.\)/\u\1/g')
					fi
					_newLine="$_line \"$_dest"
					echo "> \$_newLine=$_newLine" #Debug
					echo "> \$unpackedDir/\$mod/\$_item/=$unpackedDir/$mod/$_item/" #Debug
					echo "> optionalFolderDests[\$_iteration] = ${optionalFolderDests[$_iteration]}" #Debug
					echo "$_newLine" >> "$manifestDir/$mod.txt" #Debug
				fi
			done
			_iteration=$(bc <<< "$_iteration+1")
		done
	fi
	unset IFS
}

# MAIN

if [[ ! -d "$defaultDir" ]]; then
	echo "Please enter the absolute path to your '<GAME>/Data' directory"
	PromptUser dir "Enter a valid directory" 0 0 "/path/to/directory"
	SetVar defaultDir "$promptResult" $configPath bash string
fi

source $configPath
if [[ -z $appID ]]; then
	_steamGameName=$(echo "$defaultDir" | sed "s|.*common/||g" | sed "s|/.*||g")
	case "$_steamGameName" in
		"${fallout4[3]}")
			echo "> Fallout 4 detected!"
			sleep 1
			SetVar appID "${fallout4[0]}" $configPath bash number
			SetVar gameNameINI "${fallout4[1]}" $configPath bash string
			SetVar myGamesName "${fallout4[2]}" $configPath bash string
			SetVar gameName2 "${fallout4[3]}" $configPath bash string
			SetVar scriptExtender "${fallout4[4]}" $configPath bash string
			appID="${fallout4[0]}"
			myGamesName="${fallout4[2]}"
			gameNameINI="${fallout4[1]}"
			gameINIDir=$(echo "$defaultDir" | sed "s|common/.*||g")"compatdata/$appID/pfx/drive_c/users/steamuser/Documents/My Games/$myGamesName"
			pluginsTXT=$(echo "$defaultDir" | sed "s|common/.*||g")"compatdata/$appID/pfx/drive_c/users/steamuser/AppData/Local/$myGamesName/Plugins.txt"
			SetVar pluginsTXT "$pluginsTXT" "$configPath" bash string
			gameCustomINIPath="$gameINIDir/$gameNameINI"
			SetVar gameCustomINIPath "$gameCustomINIPath" "$configPath" bash string

		;;
		"${fallout3[3]}")
			echo "> Fallout 3 detected!"
			sleep 1
			_list=$(printf "Fallout 3\nFallout 3 Game Of The Year Edition\n")
			PresentList "$_list" "Please enter the number for the game you own on Steam."
			itemSelected=$presentListResult
			appID=
			if [[ "$itemSelected" == "Fallout 3 Game Of The Year Edition" ]]; then
				appID="${fallout3GOTY[0]}"
				SetVar gameName2 "Fallout 3 Game Of The Year Edition" $configPath bash string
			else
				appID="${fallout3[0]}"
				SetVar gameName2 "${fallout3[3]}" $configPath bash string
			fi
			SetVar appID "$appID" $configPath bash number
			SetVar gameNameINI "${fallout3[1]}" $configPath bash string
			SetVar myGamesName "${fallout3[2]}" $configPath bash string
			SetVar scriptExtender "${fallout3[4]}" $configPath bash string
			myGamesName="${fallout3[2]}"
			gameNameINI="${fallout3[1]}"
			gameINIDir=$(echo "$defaultDir" | sed "s|common/.*||g")"compatdata/$appID/pfx/drive_c/users/steamuser/Documents/My Games/$myGamesName"
			pluginsTXT=$(echo "$defaultDir" | sed "s|common/.*||g")"compatdata/$appID/pfx/drive_c/users/steamuser/AppData/Local/$myGamesName/Plugins.txt"
			SetVar pluginsTXT "$pluginsTXT" "$configPath" bash string
			gameCustomINIPath="$gameINIDir/$gameNameINI"
			SetVar gameCustomINIPath "$gameCustomINIPath" "$configPath" bash string
		;;
		"${skyrimSE[3]}")
			echo "> Skyrim Special Edition detected!"
			sleep 1
			appID="${skyrimSE[0]}"
			SetVar appID "$appID" $configPath bash number
			SetVar gameNameINI "${skyrimSE[1]}" $configPath bash string
			SetVar myGamesName "${skyrimSE[2]}" $configPath bash string
			SetVar gameName2 "Skyrim Special Edition" $configPath bash string
			SetVar scriptExtender "${skyrimSE[4]}" $configPath bash string
			appID="${skyrimSE[0]}"
			myGamesName="${skyrimSE[2]}"
			gameNameINI="${skyrimSE[1]}"
			gameINIDir=$(echo "$defaultDir" | sed "s|common/.*||g")"compatdata/$appID/pfx/drive_c/users/steamuser/Documents/My Games/$myGamesName"
			pluginsTXT=$(echo "$defaultDir" | sed "s|common/.*||g")"compatdata/$appID/pfx/drive_c/users/steamuser/AppData/Local/$myGamesName/Plugins.txt"
			SetVar pluginsTXT "$pluginsTXT" "$configPath" bash string
			gameCustomINIPath="$gameINIDir/$gameNameINI"
			SetVar gameCustomINIPath "$gameCustomINIPath" "$configPath" bash string
		;;
		"${skyrim[3]}")
			echo "> Skyrim detected!"
			sleep 1
			appID="${skyrim[0]}"
			SetVar appID "$appID" $configPath bash number
			SetVar gameNameINI "${skyrim[1]}" $configPath bash string
			SetVar myGamesName "${skyrim[2]}" $configPath bash string
			SetVar gameName2 "${skyrim[3]}" $configPath bash string
			SetVar scriptExtender "${skyrim[4]}" $configPath bash string
			appID="${skyrim[0]}"
			myGamesName="${skyrim[2]}"
			gameNameINI="${skyrim[1]}"
			gameINIDir=$(echo "$defaultDir" | sed "s|common/.*||g")"compatdata/$appID/pfx/drive_c/users/steamuser/Documents/My Games/$myGamesName"
			pluginsTXT=$(echo "$defaultDir" | sed "s|common/.*||g")"compatdata/$appID/pfx/drive_c/users/steamuser/AppData/Local/$myGamesName/Plugins.txt"
			SetVar pluginsTXT "$pluginsTXT" "$configPath" bash string
			gameCustomINIPath="$gameINIDir/$gameNameINI"
			SetVar gameCustomINIPath "$gameCustomINIPath" "$configPath" bash string
		;;
		"${oblivionGOTY[3]}")
			appID=
			echo "> Oblivion detected!"
			sleep 1
			_list=$(printf "Oblivion Game Of The Year Edition\nOblivion Game Of The Year Edition Deluxe\n")
			PresentList "$_list" "Please enter the number for the game you own on Steam."
			itemSelected=$presentListResult
			appID=
			if [[ "$itemSelected" == "Oblivion Game Of The Year Edition Deluxe" ]]; then
				appID="${oblivionGOTYD[0]}"
				SetVar gameName2 "Oblivion Game Of The Year Deluxe Edition" $configPath bash string
			else
				appID="${oblivionGOTY[0]}"
				SetVar gameName2 "Oblivion Game Of The Year Edition" $configPath bash string
			fi
			SetVar gameNameINI "${oblivionGOTYD[1]}" $configPath bash string
			SetVar myGamesName "${oblivionGOTYD[2]}" $configPath bash string
			SetVar scriptExtender "${oblivionGOTYD[4]}" $configPath bash string
			myGamesName="${oblivionGOTYD[2]}"
			gameNameINI="${oblivionGOTYD[1]}"
			gameINIDir=$(echo "$defaultDir" | sed "s|common/.*||g")"compatdata/$appID/pfx/drive_c/users/steamuser/Documents/My Games/$myGamesName"
			gameCustomINIPath="$gameINIDir/$gameNameINI"
			pluginsTXT=$(echo "$defaultDir" | sed "s|common/.*||g")"compatdata/$appID/pfx/drive_c/users/steamuser/AppData/Local/$myGamesName/Plugins.txt"
			SetVar pluginsTXT "$pluginsTXT" "$configPath" bash string
			SetVar gameCustomINIPath "$gameCustomINIPath" "$configPath" bash string
		;;
	esac
fi

while true
do
	listOfArchives=$(ls -1 $archivesDir)
	listOfMods=$(ls -1 $unpackedDir)
	clear
	source $configPath
	echo
	echo "   -BASH Mod Manager v$version-"
	echo "          $myGamesName"
	echo
	
	if [[ "$message" =~ [Aa|Ee|Ii|Oo|Uu|Yy] ]]; then
		echo "$message"
	fi
	
	archiveInvalidationStatus=
	if grep -q "bInvalidateOlderFiles=1" "$gameCustomINIPath"; then
		archiveInvalidationStatus="Deactivate Archive Invalidation"
	elif [[ ! -f $gameCustomINIPath ]]; then
		archiveInvalidationStatus="ERROR: No gameNameINI"
	else
		archiveInvalidationStatus="Activate Archive Invalidation"
	fi
	
	scriptExtenderStatus=
	gamePath=$(echo "$defaultDir" | sed "s|/[Dd]ata.*||g")
	scriptExtenderEXE="$scriptExtender""_loader.exe"
	scriptExtenderPath="$gamePath/$scriptExtenderEXE"
	launcherPath="$gamePath/$myGamesName""Launcher.exe"
	if [[ ! -f "$launcherPath.bak" ]]; then	
		scriptExtenderStatus="Activate"
	else
		scriptExtenderStatus="Deactivate"
	fi
	
	optionsList=$(printf "Install Mod\nEnable Mod\nDisable Mod\nUninstall Mod\nEdit Load Order\n$archiveInvalidationStatus\n$scriptExtenderStatus $scriptExtender\nEXIT")
	PresentList "$optionsList" "   Please select an option"
	message=""
	optionSelected=$presentListResult
	case "$optionSelected" in
		"Install Mod")
			InstallArchive
		;;
		"Enable Mod")
			EnableMod
		;;
		"Disable Mod")
			DisableMod
		;;
		"Uninstall Mod")
			UninstallMod
		;;
		"Edit Load Order")
			EditPlugins
		;;
		"Activate Archive Invalidation")
			ArchiveInvalidation "activate"
		;;
		"Deactivate Archive Invalidation")
			ArchiveInvalidation "deactivate"
		;;
		"Activate $scriptExtender")
			ScriptExtender activate
		;;
		"Deactivate $scriptExtender")
			ScriptExtender deactivate
		;;
		"EXIT")
			exit
		;;
	esac
done
