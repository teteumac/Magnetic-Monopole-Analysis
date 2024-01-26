# Generation and Simulation

## Instructions for Generating Events with MadGraph

First, you must configure the environment. Inside the repository you can see the executable `environment_config_mg5.sh`.
Edit this script fallowing the steps:
* Choice the CMSSW release in the line 4 and modified the line 7 too.
* The line 33 and 36, change the path to you path until `$YOUPATH/src/MG5_aMC_v2_9_16/HEPTools/lhapdf6_py3/share/LHAPDF`
* Run this code with `./environment_config_mg5.sh`
* Open the new terminal
* Enter inside the CMSSW release that you create, for exemple `cd CMSSW_10_6_22/src/MG5_aMC_v2_9_16`
* Run this command to have acess the python 3.8 `source /afs/cern.ch/user/m/matheus/public/hepenv_setup.sh`
   
Now you may be able to run the code for generating the events.
The `Events_Generate_Mono_MG5.py` file is responsible for the entire generation process. On lines 39 and 40 you should change the paths to the absolute path of the madgraph(`MADGRAPH_PATH_RUN`) and the output in your `eos` where the generation will be saved (`OUTPUT_DIR`).

    
     MADGRAPH_PATH_RUN = '/afs/cern.ch/user/m/matheus/CMSSW_10_6_24/src/MG5_aMC_v2_9_15/bin/mg5_aMC'
     OUTPUT_DIR = '/eos/home-m/matheus/magnetic_monopole_output'

The shell code `submit_mg5_condor.sh` is the executable that will be allocated to the condor (`condor_sub_mg5.sub`)

If you want to generate local code, just run it locally using

   
    python3 Events_Generate_Mono_MG5.py -mass 1000 -events 500 -process "photon_fusion" -spin "zero" -seed_rnd 1

    -mass 1000 --> Monopole mass
    -events 500 --> How many events do you want to generate
    -itera 10 --> Number of times you want to generate the same code
    -process photon_fusion --> Which process do you want to run: Drell Yan or Photon Fusion
    -spin half --> Which spin do you want: Spin 0 or Spin 1/2
    -seed_rnd --> Random seed used to generate different samples

*OBSERVATION:* Remember to change all code directories to yours.

For this analysis we are using recent results obtained by ATLAS on the lower limits of the monopole mass:
                
<table>
    <tr>
        <th>Process and Spin</th>
        <th>|g| = 1gD</th>
        <th>|g| = 2gD</th>
        <th>|z| = 20</th>
        <th>|z| = 40</th>
        <th>|z| = 60</th>
        <th>|z| = 80</th>
        <th>|z| = 100</th>
    </tr>
    <tr>
        <td>DY spin-0</td>
        <td>2.1</td>
        <td>2.1</td>
        <td>1.4</td>
        <td>1.8</td>
        <td>1.9</td>
        <td>1.8</td>
        <td>1.7</td>
    </tr>
    <tr>
        <td>DY spin-1/2</td>
        <td>2.6</td>
        <td>2.5</td>
        <td>1.8</td>
        <td>2.2</td>
        <td>2.2</td>
        <td>2.1</td>
        <td>1.9</td>
    </tr>
    <tr>
        <td>PF spin-0</td>
        <td>3.4</td>
        <td>3.5</td>
        <td>2.1</td>
        <td>2.8</td>
        <td>2.9</td>
        <td>2.8</td>
        <td>2.5</td>
    </tr>
    <tr>
        <td>PF spin-1/2</td>
        <td>3.6</td>
        <td>3.7</td>
        <td>2.5</td>
        <td>3.1</td>
        <td>3.1</td>
        <td>3.0</td>
        <td>2.5</td>
    </tr>
    <tr>
        <td colspan="8"><a href="https://arxiv.org/pdf/2308.04835.pdf">Source: Search for magnetic monopoles and stable particles
with high electric charges in √𝒔 =13 TeV 𝒑 𝒑 collisions with the ATLAS detector. Table 2, pag 13</a></td>
    </tr>
</table>

This table shows the first two columns with the value of the monopole's magnetic charge and the last are the HECOs particles charge.

When the condor over, you must have 2000 files. You can count how files you have with these command 
      
      find /eos/home-m/matheus/magnetic_monopole_output -maxdepth 1 -type f | wc -l


## Simulations Steps 

### Simulation Stage for Run II

For the simulation stage, the entire process was divided to be carried out over the 3 years of Run II. However, it is necessary to publish 5 releases to acquire the AOD files for 3 years.

#### Releases Required

You will need the following CMSSW releases:

- `CMSSW_10_2_16_UL`
- `CMSSW_10_6_22`
- `CMSSW_10_6_23`
- `CMSSW_8_0_33_UL`
- `CMSSW_9_4_14_UL`
- `CMSSW_9_4_14_UL_patch1`

#### Automation with HTCondor

Only the `CMSSW_10_6_23` release makes the entire process automated by HTCondor.

#### Customizing the Simulation

Within `CMSSW_10_6_23/src`, you can find the code `simulation_Run2.sh` and modify the relevant paths, as well as the year of execution which is on line 20, if you want 2018, 2017 or 2016. Line 16 is the address of the file that leads to all files in `.lhe` format to run on HTCondor.

To run the process you can run it using `condor_submit condor_sim_reco.sub`

`--customise_commands process.AODSIMoutput.outputCommands.append('keep *_siStripClusters_*_*') \n process.AODSIMoutput.outputCommands.append('keep *_siPixelClusters_*_*') \n process.AODSIMoutput.outputCommands.append('drop *_generalTracks_*_*')`
