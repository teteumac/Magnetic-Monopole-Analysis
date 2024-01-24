#!/bin/bash


# Script for generating events using MadGraph for different configurations of monopole masses and spins.
# 
# Phases:
# 1. Generate events for monopoles with spin "half" and process "photon_fusion" for masses of 800, 1000, 1200 and 1400.
# 2. Generate events for monopoles with spin "zero" and process "photon_fusion" for masses of 800, 1000, 1200 and 1400.
# 3. Generate events for monopoles with spin "half" and process "drell_yan" for masses of 800, 1000, 1200 and 1400.
# 4. Generate events for monopoles with spin "zero" and process "drell_yan" for masses of 800, 1000, 1200 and 1400.
# 
# 
# ######## Drell Yan Process ########
# 
# q                                    M+
#   *                                *
#      *                          *
#         *                    *
#            *      Z*/γ    *
#             **************
#            *              *
#         *                    *
#     *                           *
# *                                  *
# q̄                                    M-
# 
# ######## Photon Fusion Process ########
# 
# 
# γ                                     M+
#   *                                *
#      *                          *
#         *                    *
#            *              *
#             **************
#            *              *
#         *                    *
#     *                           *
# *                                  *
# γ                                    M-
# 
# 
# Lower limits on the mass of magnetic monopoles and HECOs (in TeV) at 95% confidence level in models of
#                   spin-0 and spin-1/2 Drell-Yan (DY) and photon-fusion (PF) pair production
#  __________________________________________________________________________________________________                  
# |                                                                                                  |   
# | Process and Spin | |g| = 1gD | |g| = 2gD | |z| = 20 | |z| = 40 | |z| = 60 | |z| = 80 | |z| = 100 |
# |------------------|-----------|-----------|----------|----------|----------|----------|-----------|
# |   DY spin-0      | 2.1       | 2.1       | 1.4      | 1.8      | 1.9      | 1.8      | 1.7       |
# |   DY spin-1/2    | 2.6       | 2.5       | 1.8      | 2.2      | 2.2      | 2.1      | 1.9       |
# |   PF spin-0      | 3.4       | 3.5       | 2.1      | 2.8      | 2.9      | 2.8      | 2.5       |
# |   PF spin-1/2    | 3.6       | 3.7       | 2.5      | 3.1      | 3.1      | 3.0      | 2.5       |
# |                                                                                                  |
# |                https://arxiv.org/pdf/2308.04835.pdf --> Table 2, pag 13                          |
# |__________________________________________________________________________________________________|


SCRIPT_PATH="/afs/cern.ch/user/m/matheus/CMSSW_10_6_22/src/MG5_aMC_v2_9_16/Events_Generate_Mono_MG5.py"

# Lista de massas
masses=(1000 1500 2000 2500 3000 3400 3500 3600 3700 3800 3900 4000 4100 4200 4300 4400 4500)

# Loop externo para as massas
for mass in "${masses[@]}"
do
    # Loop interno para executar o script 4 vezes para cada massa
    for i in {1..200}
    do
        echo "Execução $i de 200 para a massa $mass"

        # Chamar o script Python com os argumentos necessários, incluindo run_id e a massa
        python $SCRIPT_PATH -mass $mass -events 500 -process "photon_fusion" -spin "half" -seed_rnd $i 
        python $SCRIPT_PATH -mass $mass -events 500 -process "photon_fusion" -spin "zero" -seed_rnd $i
        # Aguardar um breve momento entre as execuções (opcional)
        sleep 1
    done
done

echo "Execuções completadas."

#python $SCRIPT_PATH -mass 1000 -events 10 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 1000 -events 10 -process "photon_fusion" -spin "half" -run_id 1
#python $SCRIPT_PATH -mass 2000 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 2500 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 3000 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 3500 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 4000 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 4500 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#
## ATLAS mass
#python $SCRIPT_PATH -mass 3600 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 3700 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 3800 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 3900 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 4000 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 4100 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 4200 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 4300 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#python $SCRIPT_PATH -mass 4400 -events 100000 -process "photon_fusion" -spin "half" -run_id 0
#
## -------------------------------------------------------------------- #
#
#python $SCRIPT_PATH -mass 1000 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 1500 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 2000 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 2500 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 3000 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 3500 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 4000 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 4500 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0

# ATLAS mass
#python $SCRIPT_PATH -mass 3600 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 3700 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 3800 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 3900 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 4000 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 4100 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 4200 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 4300 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0
#python $SCRIPT_PATH -mass 4400 -events 100000 -process "photon_fusion" -spin "zero" -run_id 0


#touch ListFile_condor.txt
#find /eos/home-m/matheus/magnetic_monopole_output/*.lhe > /afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src/ListFile_condor.txt # Para todos os arquivos

#Para todos os arquivos find /eos/home-m/matheus/magnetic_monopole_output/SpinHalf_PF_*_mass_1000_*.lhe > /afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src/ListFile_condor.txt
#Para mais de um padrao find /eos/home-m/matheus/magnetic_monopole_output/ \( -name 'SpinHalf_PF_*_mass_1000_*.lhe' -o -name 'SpinHalf_PF_*_mass_1500_*.lhe' -o -name 'SpinHalf_PF_*_mass_2000_*.lhe' -o -name 'SpinHalf_PF_*_mass_2500_*.lhe' -o -name 'SpinHalf_PF_*_mass_3000_*.lhe' -o -name 'SpinHalf_PF_*_mass_3500_*.lhe' -o -name 'SpinHalf_PF_*_mass_4500_*.lhe' \) > /afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src/ListFile_condor.txt

