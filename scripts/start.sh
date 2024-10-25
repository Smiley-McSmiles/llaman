#!/bin/bash

defaultDir=/opt/open-webui
openWebuiStart=$defaultDir/open-webui/backend/start.sh
condaDir=$defaultDir/config/conda
condaEnv=$condaDir/open-webui

#source /etc/profile.d/conda.sh
source /usr/etc/profile.d/conda.sh
conda activate $condaEnv
$openWebuiStart
