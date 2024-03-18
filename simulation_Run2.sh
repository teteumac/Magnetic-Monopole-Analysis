#!/bin/bash

# find /eos/home-m/matheus/magnetic_monopole_output/SpinZero_PF_*_mass_1000_events_500.lhe > /afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src/ListFile_condor.txt

# Initialize the proxy certificate
# voms-proxy-init --rfc --voms cms -valid 192:00 -out $HOME/x509up_u130329
# After, run this command before execute with HTCondor

# Para fazer o merged usar esse comando
# hadd /eos/home-m/matheus/magnetic_monopole_Analysis/SpinHalf_PF_Merged_mass_1500_events_500_AOD_2018_SpikeTopo_UncerSyst.root SpinHalf_PF_*_mass_1500_events_500_AOD_2018_SpikeTopo_UncerSyst.root

#cmsenv
#scram b -j 4
source /cvmfs/cms.cern.ch/cmsset_default.sh
export SCRAM_ARCH=slc7_amd64_gcc700
#eval `scramv1 project CMSSW CMSSW_10_6_23`
#cd /afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src
eval `scramv1 runtime -sh` # cmsenv is an alias not on the workers
echo "CMSSW: "$CMSSW_BASE


# Defina se as incertezas sistemáticas devem ser consideradas
export SPIKE_KILLING_UNCERTAINTY=False
export DELTA_RAY_UNCERTAINTY=False
export dEdXCrossTalk_TrackerSubDetector_UNCERTAINTY=True

percentage=-0.1  # Exemplo de 10% de incremento ou decremento. Pode ser alterado para qualquer valor desejado.

# Converter a porcentagem em um valor absoluto para evitar problemas com a comparação de ponto flutuante.
absolute_percentage=$(echo "$percentage" | awk '{print ($1 >= 0) ? $1 : 0 - $1}')

# O caminho do arquivo é fixo
#file=/eos/home-m/matheus/magnetic_monopole_output/SpinZero_PF_137_mass_2000_events_500.lhe
file=$1

# O ano é passado como o primeiro argumento para o script
year=2018

number_of_events=-1

# You need create this directory in your EOS
output_path="/eos/home-m/matheus/magnetic_monopole_output_AOD"


# Definir sufixos com base nas incertezas sistemáticas que serão consideradas
suffix=""

if [ "$DELTA_RAY_UNCERTAINTY" = "True" ]; then
    suffix="_DeltaE_UncerSyst"
elif [ "$SPIKE_KILLING_UNCERTAINTY" = "True" ]; then
    suffix="_SpikeTopo_UncerSyst"
elif [ "$dEdXCrossTalk_TrackerSubDetector_UNCERTAINTY" = "True" ]; then
    # Determinar se é incremento ou decremento e formatar a porcentagem para remover o ponto decimal
    # Isso é necessário para criar o sufixo corretamente.
    formatted_percentage=$(echo "$absolute_percentage" | awk '{printf "%d", $1 * 100}')
    if [ "$(echo "$percentage >= 0" | bc)" -eq 1 ]; then
        suffix="_dEdX_CrossTalk_${formatted_percentage}up_UncerSyst"
    else
        suffix="_dEdX_CrossTalk_${formatted_percentage}down_UncerSyst"
    fi
fi

echo $suffix

# Get the base name of the file without the path
base=$(basename "$file")

echo "Processing file: $file"

# --------- LHE STEP --------- # 

# Check the year and execute the corresponding cmsDriver.py command
if [ "$year" == "2018" ]; then
    cmsDriver.py step1 --filein "file:$file" --fileout "file:$output_path/${base%.lhe}_LHE_${year}.root" --mc --eventcontent LHE --datatier LHE --conditions 106X_upgrade2018_realistic_v16_L1v1 --step NONE --python_filename "${base%.lhe}_LHE_${year}_cfg.py" --no_exec -n $number_of_events --customise_commands "process.source.firstLuminosityBlock = cms.untracked.uint32(3)"
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

if [ "$year" == "2018" ]; then
    customise_commands="from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper; randSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService); randSvc.populate()\nprocess.g4SimHits.Physics.MonopoleMass = $mass"

    # Verifica se a incerteza de DELTA_RAY deve ser considerada
    if [ "$DELTA_RAY_UNCERTAINTY" = "True" ]; then
        customise_commands+="\nprocess.g4SimHits.Physics.MonopoleDeltaRay = cms.untracked.bool(False)"
    fi

    cmsDriver.py Configuration/GenProduction/python/Hadronizer_TuneCP5_13TeV_generic_LHE_pythia8_cff.py --filein file:$output_path/${base%.lhe}_LHE_${year}.root --fileout file:$output_path/${base%.lhe}_GENSIM_${year}.root --mc --eventcontent RAWSIM --datatier GEN-SIM --conditions 106X_upgrade2018_realistic_v16_L1v1 --step GEN,SIM --beamspot Realistic25ns13TeVEarly2018Collision --geometry DB:Extended --era Run2_2018 --python_filename "${base%.lhe}_GENSIM_${year}_cfg.py" --customise_commands "$customise_commands" --no_exec --nThreads 8 -n -1

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

    customise_commands="from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper; randSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService); randSvc.populate()"

    # Verifica se a incerteza de dEdXCrossTalk deve ser considerada
    if [ "$dEdXCrossTalk_TrackerSubDetector_UNCERTAINTY" = "True" ]; then
        # Calcula o fator de ajuste baseado na porcentagem fornecida
        # Incremento (percentage positivo) ou Decremento (percentage negativo)
        adjustment_factor=$(echo "1 + $percentage" | bc -l)

        customise_commands+="\nprocess.SiStripSimBlock.CouplingConstantRunIIDecIB1 = cms.vdouble($(echo "0.8361 * $adjustment_factor" | bc), $(echo "0.0703 * $adjustment_factor" | bc), $(echo "0.0117 * $adjustment_factor" | bc))\n"
        customise_commands+="process.SiStripSimBlock.CouplingConstantRunIIDecIB2 = cms.vdouble($(echo "0.8616 * $adjustment_factor" | bc), $(echo "0.0588 * $adjustment_factor" | bc), $(echo "0.0104 * $adjustment_factor" | bc))\n"
        customise_commands+="process.SiStripSimBlock.CouplingConstantRunIIDecOB2 = cms.vdouble($(echo "0.7925 * $adjustment_factor" | bc), $(echo "0.0834 * $adjustment_factor" | bc), $(echo "0.0203 * $adjustment_factor" | bc))\n"
        customise_commands+="process.SiStripSimBlock.CouplingConstantRunIIDecOB1 = cms.vdouble($(echo "0.7461 * $adjustment_factor" | bc), $(echo "0.0996 * $adjustment_factor" | bc), $(echo "0.0273 * $adjustment_factor" | bc))\n"
        customise_commands+="process.SiStripSimBlock.CouplingConstantRunIIDecW1a = cms.vdouble($(echo "0.8571 * $adjustment_factor" | bc), $(echo "0.0608 * $adjustment_factor" | bc), $(echo "0.0106 * $adjustment_factor" | bc))\n"
        customise_commands+="process.SiStripSimBlock.CouplingConstantRunIIDecW2a = cms.vdouble($(echo "0.8861 * $adjustment_factor" | bc), $(echo "0.0490 * $adjustment_factor" | bc), $(echo "0.0080 * $adjustment_factor" | bc))\n"
        customise_commands+="process.SiStripSimBlock.CouplingConstantRunIIDecW3a = cms.vdouble($(echo "0.8984 * $adjustment_factor" | bc), $(echo "0.0494 * $adjustment_factor" | bc), $(echo "0.0014 * $adjustment_factor" | bc))\n"
        customise_commands+="process.SiStripSimBlock.CouplingConstantRunIIDecW1b = cms.vdouble($(echo "0.8827 * $adjustment_factor" | bc), $(echo "0.0518 * $adjustment_factor" | bc), $(echo "0.0068 * $adjustment_factor" | bc))\n"
        customise_commands+="process.SiStripSimBlock.CouplingConstantRunIIDecW2b = cms.vdouble($(echo "0.8943 * $adjustment_factor" | bc), $(echo "0.0483 * $adjustment_factor" | bc), $(echo "0.0046 * $adjustment_factor" | bc))\n"
        customise_commands+="process.SiStripSimBlock.CouplingConstantRunIIDecW3b = cms.vdouble($(echo "0.8611 * $adjustment_factor" | bc), $(echo "0.0573 * $adjustment_factor" | bc), $(echo "0.0121 * $adjustment_factor" | bc))\n"
        customise_commands+="process.SiStripSimBlock.CouplingConstantRunIIDecW4  = cms.vdouble($(echo "0.8881 * $adjustment_factor" | bc), $(echo "0.0544 * $adjustment_factor" | bc), $(echo "0.0015 * $adjustment_factor" | bc))\n"
        customise_commands+="process.SiStripSimBlock.CouplingConstantRunIIDecW5  = cms.vdouble($(echo "0.7997 * $adjustment_factor" | bc), $(echo "0.0770 * $adjustment_factor" | bc), $(echo "0.0231 * $adjustment_factor" | bc))\n"
        customise_commands+="process.SiStripSimBlock.CouplingConstantRunIIDecW6  = cms.vdouble($(echo "0.8067 * $adjustment_factor" | bc), $(echo "0.0769 * $adjustment_factor" | bc), $(echo "0.0198 * $adjustment_factor" | bc))\n"
        customise_commands+="process.SiStripSimBlock.CouplingConstantRunIIDecW7  = cms.vdouble($(echo "0.7883 * $adjustment_factor" | bc), $(echo "0.0888 * $adjustment_factor" | bc), $(echo "0.0171 * $adjustment_factor" | bc))\n"
    fi

    cmsDriver.py step1 --filein file:$output_path/${base%.lhe}_GENSIM_${year}.root --fileout file:$output_path/${base%.lhe}_DIGI_${year}.root --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX" --mc --eventcontent PREMIXRAW --runUnscheduled --datatier GEN-SIM-DIGI --conditions 106X_upgrade2018_realistic_v16_L1v1 --step DIGI,DATAMIX,L1,DIGI2RAW --procModifiers premix_stage2 --nThreads 8 --geometry DB:Extended --datamix PreMix --era Run2_2018 --python_filename "${base%.lhe}_DIGI_${year}_cfg.py" --no_exec -n -1 --customise_commands "$customise_commands"

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
cmsenv
echo "CMSSW: "$CMSSW_BASE

if [ "$year" == "2018" ]; then
    # Constrói a string de comandos de personalização base
    customise_commands="process.AODSIMoutput.outputCommands.append('keep *_generatorSmeared_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_hybridSuperClusters_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_multi5x5SuperClusters_multi5x5EndcapSuperClusters_*') \n process.AODSIMoutput.outputCommands.append('keep *_multi5x5SuperClusters_uncleanOnlyMulti5x5EndcapBasicClusters_*') \n process.AODSIMoutput.outputCommands.append('keep *_multi5x5SuperClusters_uncleanOnlyMulti5x5EndcapSuperClusters_*') \n process.AODSIMoutput.outputCommands.append('keep *_siStripClusters_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_siPixelClusters_*_*') \n process.AODSIMoutput.outputCommands.append('drop *_generalTracks_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_generalTracks_*_*') \n process.AODSIMoutput.outputCommands.append('drop *_generalTracks_QualityMasks_*') \n process.AODSIMoutput.outputCommands.append('keep *_ecalRecHit_EcalRecHitsEB_*') \n process.AODSIMoutput.outputCommands.append('keep *_ecalRecHit_EcalRecHitsEE_*') \n process.AODSIMoutput.outputCommands.append('keep *_hbhereco_*_*') \n process.Timing.summaryOnly = cms.untracked.bool(True) \n process.Timing.excessiveTimeThreshold = cms.untracked.double(30.0)"

    # Verifica se a incerteza SPIKE_KILLING deve ser considerada
    if [ "$SPIKE_KILLING_UNCERTAINTY" = "True" ]; then
        customise_commands+="\n process.particleFlowRecHitECAL.timingCleaning = cms.bool(False) \n process.particleFlowRecHitECAL.topologicalCleaning = cms.bool(True)"
    fi

    cmsDriver.py step3 --filein file:$output_path/${base%.lhe}_HLT_${year}.root --fileout file:$output_path/${base%.lhe}_RECO_${year}.root --mc --eventcontent AODSIM --datatier AODSIM --conditions 106X_upgrade2018_realistic_v16_L1v1 --step RAW2DIGI,L1Reco,RECO,RECOSIM --nThreads 8 --runUnscheduled --geometry DB:Extended --era Run2_2018 --customise=Configuration/DataProcessing/Utils.addMonitoring --customise_commands "$customise_commands" --python_filename "${base%.lhe}_RECO_${year}_cfg.py" --no_exec -n -1

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
rm -f /afs/cern.ch/user/m/matheus/CMSSW_10_2_16_UL/src/${base%.lhe}_HLT_${year}_cfg.py


# --------- AOD STEP --------- # 

# Checar o ano e executar o comando cmsRun correspondente
if [ "$year" == "2018" ]; then
    cmsRun /afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src/ntuple_mc_2018_cfg.py inputFiles="file:$output_path/${base%.lhe}_RECO_${year}.root" outputFile=$output_path/${base%.lhe}_AOD_${year}${suffix}.root
elif [ "$year" == "2017" ]; then
    cmsRun /afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src/ntuple_mc_2017_cfg.py inputFiles="file:$output_path/${base%.lhe}_RECO_${year}.root" outputFile=$output_path/${base%.lhe}_AOD_${year}${suffix}.root
elif [ "$year" == "2016" ]; then
    cmsRun /afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src/ntuple_mc_2016_cfg.py inputFiles="file:$output_path/${base%.lhe}_RECO_${year}.root" outputFile=$output_path/${base%.lhe}_AOD_${year}${suffix}.root
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
rm -f ${base%.lhe}_DIGI_${year}_cfg.py
rm -f /afs/cern.ch/user/m/matheus/CMSSW_10_2_16_UL/src/${base%.lhe}_HLT_${year}_cfg.py

echo "Cleanup completed successfully."
