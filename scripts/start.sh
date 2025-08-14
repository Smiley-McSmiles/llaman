#!/bin/bash

defaultDir=/opt/open-webui
configFile=$defaultDir/config/llaman.conf
source $configFile

condaSh=$defaultDir/miniconda3/etc/profile.d/conda.sh
condaEnv=$defaultDir/config/conda/open-webui
openWebuiStart="open-webui serve --port $httpPort"

source $condaSh
conda activate $condaEnv
$openWebuiStart