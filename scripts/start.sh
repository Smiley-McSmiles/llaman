#!/bin/bash

configFile=/opt/open-webui/config/llaman.conf
source $configFile

defaultDir=/opt/open-webui
condaSh=$defaultDir/miniconda3/etc/profile.d/conda.sh
condaEnv=$defaultDir/config/conda/open-webui
openWebuiStart="open-webui serve --port $httpPort"

source $condaSh
conda activate $condaEnv
$openWebuiStart