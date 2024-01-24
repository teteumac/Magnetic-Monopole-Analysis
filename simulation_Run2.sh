#!/bin/bash

# Initialize the proxy certificate
# voms-proxy-init --rfc --voms cms -valid 192:00 -out $HOME/x509up_u130329
# After, run this command before execute with HTCondor

source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc7_amd64_gcc700
eval `scramv1 project CMSSW CMSSW_10_6_23`
cd /afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src
eval `scramv1 runtime -sh` # cmsenv is an alias not on the workers
echo "CMSSW: "$CMSSW_BASE

# O caminho do arquivo é fixo
#file=/eos/home-m/matheus/magnetic_monopole_output/SpinHalf_PF_62_mass_1500_events_500.lhe
file=$1

# O ano é passado como o primeiro argumento para o script
#year=$1
year=2018

# Get the base name of the file without the path
base=$(basename "$file")

echo "Processing file: $file"

# You need create this directory in your EOS
output_path="/eos/home-m/matheus/magnetic_monopole_output_AOD"

# --------- LHE STEP --------- # 

# Check the year and execute the corresponding cmsDriver.py command
if [ "$year" == "2018" ]; then
    cmsDriver.py step1 --filein "file:$file" --fileout "file:$output_path/${base%.lhe}_LHE_${year}.root" --mc --eventcontent LHE --datatier LHE --conditions 106X_upgrade2018_realistic_v16_L1v1 --step NONE --python_filename "${base%.lhe}_LHE_${year}_cfg.py" --no_exec -n 50000 --customise_commands "process.source.firstLuminosityBlock = cms.untracked.uint32(3)"
elif [ "$year" == "2017" ]; then
    cmsDriver.py step1 --filein "file:$file" --fileout "file:$output_path/${base%.lhe}_LHE_${year}.root" --mc --eventcontent LHE --datatier LHE --conditions 106X_mc2017_realistic_v9 --step NONE --python_filename "${base%.lhe}_LHE_${year}_cfg.py" --no_exec -n -1 --customise_commands "process.source.firstLuminosityBlock = cms.untracked.uint32(3)"
elif [ "$year" == "2016" ]; then
    cmsDriver.py step1 --filein "file:$file" --fileout "file:$output_path/${base%.lhe}_LHE_${year}.root" --mc --eventcontent LHE --datatier LHE --conditions 106X_mcRun2_asymptotic_v13 --step NONE --python_filename "${base%.lhe}_LHE_${year}_cfg.py" --no_exec -n -1 --customise_commands "process.source.firstLuminosityBlock = cms.untracked.uint32(3)"
else
    echo "Year not recognized. Please specify 2016, 2017, or 2018."
fi

# Execute the cmsRun command and redirect the output to the created directory
cmsRun "${base%.lhe}_LHE_${year}_cfg.py"

echo "Processing for file $file to LHE step completed successfully"

# --------- GENSIM STEP --------- # 

mass=$(echo $base | sed -n 's/.*_mass_\([0-9]*\)_events.*/\1/p')

# Checar o ano e executar o comando cmsDriver.py correspondente
if [ "$year" == "2018" ]; then
    cmsDriver.py Configuration/GenProduction/python/Hadronizer_TuneCP5_13TeV_generic_LHE_pythia8_cff.py --filein file:$output_path/${base%.lhe}_LHE_${year}.root --fileout file:$output_path/${base%.lhe}_GENSIM_${year}.root --mc --eventcontent RAWSIM --datatier GEN-SIM --conditions 106X_upgrade2018_realistic_v16_L1v1 --step GEN,SIM --beamspot Realistic25ns13TeVEarly2018Collision --geometry DB:Extended --era Run2_2018 --python_filename "${base%.lhe}_GENSIM_${year}_cfg.py" --customise_commands "from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper; randSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService); randSvc.populate()\nprocess.g4SimHits.Physics.MonopoleMass = $mass" --no_exec --nThreads 8 -n -1
elif [ "$year" == "2017" ]; then
    cmsDriver.py Configuration/GenProduction/python/Hadronizer_TuneCP5_13TeV_generic_LHE_pythia8_cff.py --filein file:$output_path/${base%.lhe}_LHE_${year}.root --fileout file:$output_path/${base%.lhe}_GENSIM_${year}.root --mc --eventcontent RAWSIM --datatier GEN-SIM --conditions 106X_mc2017_realistic_v9 --step GEN,SIM --beamspot Realistic25ns13TeVEarly2017Collision --geometry DB:Extended --era Run2_2017 --python_filename "${base%.lhe}_GENSIM_${year}_cfg.py" --customise_commands "from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper; randSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService); randSvc.populate()\nprocess.g4SimHits.Physics.MonopoleMass = $mass" --no_exec --nThreads 8 -n -1
elif [ "$year" == "2016" ]; then
    cmsDriver.py Configuration/GenProduction/python/Hadronizer_TuneCP5_13TeV_generic_LHE_pythia8_cff.py --filein file:$output_path/${base%.lhe}_LHE_${year}.root --fileout file:$output_path/${base%.lhe}_GENSIM_${year}.root --mc --eventcontent RAWSIM --datatier GEN-SIM --conditions 106X_mcRun2_asymptotic_v13 --step GEN,SIM --beamspot Realistic25ns13TeV2016Collision --geometry DB:Extended --era Run2_2016 --python_filename "${base%.lhe}_GENSIM_${year}_cfg.py" --customise_commands "from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper; randSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService); randSvc.populate()\nprocess.g4SimHits.Physics.MonopoleMass = $mass" --no_exec --nThreads 8 -n -1
else
    echo "Year not recognized. Please specify 2016, 2017, or 2018."
fi

# Executar o comando cmsRun para a etapa GENSIM
cmsRun "${base%.lhe}_GENSIM_${year}_cfg.py"

echo "Processing for GENSIM file $file completed successfully for year $year"

rm -f $output_path/${base%.lhe}_LHE_${year}.root
rm -f ${base%.lhe}_LHE_${year}_cfg.py

# --------- DIGI STEP --------- # 

# Checar o ano e executar o comando cmsDriver.py correspondente para a etapa DIGI
if [ "$year" == "2018" ]; then
    cmsDriver.py step1 --filein file:$output_path/${base%.lhe}_GENSIM_${year}.root --fileout file:$output_path/${base%.lhe}_DIGI_${year}.root --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX" --mc --eventcontent PREMIXRAW --runUnscheduled --datatier GEN-SIM-DIGI --conditions 106X_upgrade2018_realistic_v16_L1v1 --step DIGI,DATAMIX,L1,DIGI2RAW --procModifiers premix_stage2 --nThreads 8 --geometry DB:Extended --datamix PreMix --era Run2_2018 --python_filename "${base%.lhe}_DIGI_${year}_cfg.py" --no_exec -n -1 --customise_commands "from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper; randSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService); randSvc.populate()"
elif [ "$year" == "2017" ]; then
    cmsDriver.py step1 --filein file:$output_path/${base%.lhe}_GENSIM_${year}.root --fileout file:$output_path/${base%.lhe}_DIGI_${year}.root --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL17_106X_mc2017_realistic_v6-v3/PREMIX" --mc --eventcontent PREMIXRAW --runUnscheduled --datatier GEN-SIM-DIGI --conditions 106X_mc2017_realistic_v9 --step DIGI,DATAMIX,L1,DIGI2RAW --procModifiers premix_stage2 --nThreads 8 --geometry DB:Extended --datamix PreMix --era Run2_2017 --python_filename "${base%.lhe}_DIGI_${year}_cfg.py" --no_exec -n -1 --customise_commands "from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper; randSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService); randSvc.populate()"
elif [ "$year" == "2016" ]; then
    cmsDriver.py step1 --filein file:$output_path/${base%.lhe}_GENSIM_${year}.root --fileout file:$output_path/${base%.lhe}_DIGI_${year}.root --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL16_106X_mcRun2_asymptotic_v13-v1/PREMIX" --mc --eventcontent PREMIXRAW --runUnscheduled --datatier GEN-SIM-DIGI --conditions 106X_mcRun2_asymptotic_v13 --step DIGI,DATAMIX,L1,DIGI2RAW --procModifiers premix_stage2 --nThreads 8 --geometry DB:Extended --datamix PreMix --era Run2_2016 --python_filename "${base%.lhe}_DIGI_${year}_cfg.py" --no_exec -n -1 --customise_commands "from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper ; randSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService) ; randSvc.populate()"

else
    echo "Year not supported"
fi

cmsRun "${base%.lhe}_DIGI_${year}_cfg.py"

echo "Processing for DIGI file $file completed successfully for year $year"

rm -f $output_path/${base%.lhe}_GENSIM_${year}.root
rm -f ${base%.lhe}_GENSIM_${year}_cfg.py

# --------- HLT STEP --------- # 

#Checar o ano e executar o comando cmsDriver.py correspondente para a etapa HLT
if [ "$year" == "2018" ]; then
    cd /afs/cern.ch/user/m/matheus/CMSSW_10_2_16_UL/src
    eval `scramv1 runtime -sh`
    cmsDriver.py step2 --filein file:$output_path/${base%.lhe}_DIGI_${year}.root --fileout file:$output_path/${base%.lhe}_HLT_${year}.root --mc --eventcontent RAWSIM --datatier GEN-SIM-RAW --conditions 102X_upgrade2018_realistic_v15 --customise_commands 'process.source.bypassVersionCheck = cms.untracked.bool(True)' --step HLT:2018v32 --nThreads 8 --geometry DB:Extended --era Run2_2018 --python_filename "${base%.lhe}_HLT_${year}_cfg.py" --no_exec -n -1
elif [ "$year" == "2017" ]; then
    cd /afs/cern.ch/user/m/matheus/CMSSW_9_4_14_UL_patch1/src
    eval `scramv1 runtime -sh`
    cmsDriver.py step2 --filein file:$output_path/${base%.lhe}_DIGI_${year}.root --fileout file:$output_path/${base%.lhe}_HLT_${year}.root --mc --eventcontent RAWSIM --datatier GEN-SIM-RAW --conditions 94X_mc2017_realistic_v15 --customise_commands 'process.source.bypassVersionCheck = cms.untracked.bool(True)' --step HLT:2e34v40 --nThreads 8 --geometry DB:Extended --era Run2_2017 --python_filename "${base%.lhe}_HLT_${year}_cfg.py" --no_exec -n -1
elif [ "$year" == "2016" ]; then
    cd /afs/cern.ch/user/m/matheus/CMSSW_8_0_33_UL/src
    eval `scramv1 runtime -sh`
    cmsDriver.py step2 --filein file:$output_path/${base%.lhe}_DIGI_${year}.root --fileout file:$output_path/${base%.lhe}_HLT_${year}.root --mc --eventcontent RAWSIM --outputCommand "keep *_mix_*_*,keep *_genPUProtons_*_*" --datatier GEN-SIM-RAW --inputCommands "keep *","drop *_*_BMTF_*","drop *PixelFEDChannel*_*_*_*" --conditions 80X_mcRun2_asymptotic_2016_TrancheIV_v6 --customise_commands 'process.source.bypassVersionCheck = cms.untracked.bool(True)' --step HLT:25ns15e33_v4 --nThreads 8 --geometry DB:Extended --era Run2_2016 --python_filename "${base%.lhe}_HLT_${year}_cfg.py" --no_exec -n -1 
else
echo "Year not recognized. Please specify 2016, 2017, or 2018."
fi

# Executar o comando cmsRun para a etapa HLT

cmsRun "${base%.lhe}_HLT_${year}_cfg.py"

echo "Processing for HLT file $file completed successfully for year $year"

rm -f $output_path/${base%.lhe}_DIGI_${year}.root
rm -f ${base%.lhe}_DIGI_${year}_cfg.py


# --------- RECO STEP --------- # 

# Retornar ao diretório original
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc7_amd64_gcc700
eval `scramv1 project CMSSW CMSSW_10_6_23`
cd /afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src
eval `scramv1 runtime -sh` # cmsenv is an alias not on the workers
echo "CMSSW: "$CMSSW_BASE

# Checar o ano e executar o comando cmsDriver.py correspondente para a etapa RECO
if [ "$year" == "2018" ]; then
    cmsDriver.py step3 --filein file:$output_path/${base%.lhe}_HLT_${year}.root --fileout file:$output_path/${base%.lhe}_RECO_${year}.root --mc --eventcontent AODSIM --datatier AODSIM --conditions 106X_upgrade2018_realistic_v16_L1v1 --step RAW2DIGI,L1Reco,RECO,RECOSIM --nThreads 8 --runUnscheduled --geometry DB:Extended --era Run2_2018 --customise=Configuration/DataProcessing/Utils.addMonitoring --customise_commands "process.AODSIMoutput.outputCommands.append('keep *_generatorSmeared_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_hybridSuperClusters_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_multi5x5SuperClusters_multi5x5EndcapSuperClusters_*') \n process.AODSIMoutput.outputCommands.append('keep *_multi5x5SuperClusters_uncleanOnlyMulti5x5EndcapBasicClusters_*') \n process.AODSIMoutput.outputCommands.append('keep *_multi5x5SuperClusters_uncleanOnlyMulti5x5EndcapSuperClusters_*') \n process.AODSIMoutput.outputCommands.append('keep *_siStripClusters_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_siPixelClusters_*_*') \n process.AODSIMoutput.outputCommands.append('drop *_generalTracks_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_generalTracks_*_*') \n process.AODSIMoutput.outputCommands.append('drop *_generalTracks_QualityMasks_*') \n process.AODSIMoutput.outputCommands.append('keep *_ecalRecHit_EcalRecHitsEB_*') \n process.AODSIMoutput.outputCommands.append('keep *_ecalRecHit_EcalRecHitsEE_*') \n process.AODSIMoutput.outputCommands.append('keep *_hbhereco_*_*') \n process.Timing.summaryOnly = cms.untracked.bool(True) \n process.Timing.excessiveTimeThreshold = cms.untracked.double(30.0) \n" --python_filename "${base%.lhe}_RECO_${year}_cfg.py" --no_exec -n -1
elif [ "$year" == "2017" ]; then
    cmsDriver.py step3 --filein file:$output_path/${base%.lhe}_HLT_${year}.root --fileout file:$output_path/${base%.lhe}_RECO_${year}.root --mc --eventcontent AODSIM --datatier AODSIM --conditions 106X_mc2017_realistic_v9 --step RAW2DIGI,L1Reco,RECO,RECOSIM --nThreads 8 --runUnscheduled --geometry DB:Extended --era Run2_2017 --customise=Configuration/DataProcessing/Utils.addMonitoring --customise_commands "process.AODSIMoutput.outputCommands.append('keep *_generatorSmeared_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_hybridSuperClusters_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_multi5x5SuperClusters_multi5x5EndcapSuperClusters_*') \n process.AODSIMoutput.outputCommands.append('keep *_multi5x5SuperClusters_uncleanOnlyMulti5x5EndcapBasicClusters_*') \n process.AODSIMoutput.outputCommands.append('keep *_multi5x5SuperClusters_uncleanOnlyMulti5x5EndcapSuperClusters_*') \n process.AODSIMoutput.outputCommands.append('keep *_siStripClusters_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_siPixelClusters_*_*') \n process.AODSIMoutput.outputCommands.append('drop *_generalTracks_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_generalTracks_*_*') \n process.AODSIMoutput.outputCommands.append('drop *_generalTracks_QualityMasks_*') \n process.AODSIMoutput.outputCommands.append('keep *_ecalRecHit_EcalRecHitsEB_*') \n process.AODSIMoutput.outputCommands.append('keep *_ecalRecHit_EcalRecHitsEE_*') \n process.AODSIMoutput.outputCommands.append('keep *_hbhereco_*_*') \n process.Timing.summaryOnly = cms.untracked.bool(True) \n process.Timing.excessiveTimeThreshold = cms.untracked.double(30.0) \n" --python_filename "${base%.lhe}_RECO_${year}_cfg.py" --no_exec -n -1
elif [ "$year" == "2016" ]; then
    cmsDriver.py step3 --filein file:$output_path/${base%.lhe}_HLT_${year}.root --fileout file:$output_path/${base%.lhe}_RECO_${year}.root --mc --eventcontent AODSIM --datatier AODSIM --conditions 106X_mcRun2_asymptotic_v13 --step RAW2DIGI,L1Reco,RECO,RECOSIM --nThreads 8 --runUnscheduled --geometry DB:Extended --era Run2_2016 --customise=Configuration/DataProcessing/Utils.addMonitoring --customise_commands "process.AODSIMoutput.outputCommands.append('keep *_generatorSmeared_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_hybridSuperClusters_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_multi5x5SuperClusters_multi5x5EndcapSuperClusters_*') \n process.AODSIMoutput.outputCommands.append('keep *_multi5x5SuperClusters_uncleanOnlyMulti5x5EndcapBasicClusters_*') \n process.AODSIMoutput.outputCommands.append('keep *_multi5x5SuperClusters_uncleanOnlyMulti5x5EndcapSuperClusters_*') \n process.AODSIMoutput.outputCommands.append('keep *_siStripClusters_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_siPixelClusters_*_*') \n process.AODSIMoutput.outputCommands.append('drop *_generalTracks_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_generalTracks_*_*') \n process.AODSIMoutput.outputCommands.append('drop *_generalTracks_QualityMasks_*') \n process.AODSIMoutput.outputCommands.append('keep *_ecalRecHit_EcalRecHitsEB_*') \n process.AODSIMoutput.outputCommands.append('keep *_ecalRecHit_EcalRecHitsEE_*') \n process.AODSIMoutput.outputCommands.append('keep *_hbhereco_*_*') \n process.Timing.summaryOnly = cms.untracked.bool(True) \n process.Timing.excessiveTimeThreshold = cms.untracked.double(30.0) \n" --python_filename "${base%.lhe}_RECO_${year}_cfg.py" --no_exec -n -1
else
    echo "Year not recognized. Please specify 2016, 2017, or 2018."
fi

# Executar o comando cmsRun para a etapa RECO
cmsRun "${base%.lhe}_RECO_${year}_cfg.py"

echo "Processing for RECO file $file completed successfully for year $year"

rm -f $output_path/${base%.lhe}_HLT_${year}.root
rm -f ${base%.lhe}_HLT_${year}_cfg.py


# --------- AOD STEP --------- # 

# Checar o ano e executar o comando cmsRun correspondente
if [ "$year" == "2018" ]; then
    cmsRun /afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src/ntuple_mc_2018_cfg.py inputFiles="file:$output_path/${base%.lhe}_RECO_${year}.root" outputFile=$output_path/${base%.lhe}_AOD_${year}.root
elif [ "$year" == "2017" ]; then
    cmsRun /afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src/ntuple_mc_2017_cfg.py inputFiles="file:$output_path/${base%.lhe}_RECO_${year}.root" outputFile=$output_path/${base%.lhe}_AOD_${year}.root
elif [ "$year" == "2016" ]; then
    cmsRun /afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src/ntuple_mc_2016_cfg.py inputFiles="file:$output_path/${base%.lhe}_RECO_${year}.root" outputFile=$output_path/${base%.lhe}_AOD_${year}.root
else
    echo "Year not recognized. Please specify 2016, 2017, or 2018."
fi

echo "AOD Step for file $file completed successfully for year $year"

# --------- CLEANUP STEP --------- #

echo "Starting cleanup of intermediate files and configuration files..."

# Removing LHE, GENSIM, DIGI, HLT, RECO files
rm -f $output_path/${base%.lhe}_RECO_${year}.root

# Removing configuration files
rm -f ${base%.lhe}_RECO_${year}_cfg.py

echo "Cleanup completed successfully."