#!/bin/bash

#input_file="/eos/home-m/matheus/magnetic_monopole_output_AOD/"
input_file="/eos/cms/store/user/srimanob/monopole/13TeV/Legacy-NTUPLE-v2/merges/"

years=("2018")
#masses=("3600" "3700" "3800" "3900" "4000" "4100" "4200")
masses=("4000")


for year in "${years[@]}"
do
   for mass in "${masses[@]}"
   do
     root -l -q "/afs/cern.ch/user/m/matheus/CMSSW_10_6_24/src/MonoAnalyzerPhoton.cc(\"$year\",\"$mass\",0 ,0)"
   done
done

# to run --> root -l -q 'MonoAnalyzerPhoton.cc("2018","3600",0,0)'