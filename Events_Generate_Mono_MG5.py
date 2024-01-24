import argparse
import subprocess
import os
import fileinput
import gzip
import shutil

def main():
    MADGRAPH_PATH_RUN = '/afs/cern.ch/user/m/matheus/CMSSW_10_6_22/src/MG5_aMC_v2_9_16/bin/mg5_aMC'
    OUTPUT_DIR = '/eos/home-m/matheus/magnetic_monopole_output'

    # Creating an argument parser to accept inputs on the command line
    parser = argparse.ArgumentParser(description='Generate MadGraph configuration file.')

    # Argument to set the mass.
    parser.add_argument('-mass', 
                        type=int, 
                        required=True, 
                        help='Define the mass value for the process. It should be provided as an integer.')

    # Argument to define the number of events.
    parser.add_argument('-events', 
                        type=int, 
                        required=True, 
                        help='Specify the number of events to be generated. It should be provided as an integer.')

    # Argument to define the process.
    parser.add_argument('-process', 
                        type=str, 
                        choices=['photon_fusion', 'drell_yan'], 
                        required=True, 
                        help='Choose the physical process for generation. Two options available: "photon_fusion" or "drell_yan".')

    # Argument to define the spin.
    parser.add_argument('-spin', 
                        type=str, 
                        choices=['half', 'zero'], 
                        required=True, 
                        help='Specify the spin for the process. Two options available: "half" or "zero".')
    
    parser.add_argument('-seed_rnd', 
                    type=int, 
                    required=True, 
                    help='Random seed used to generate different samples')

    # Parse command line arguments
    args = parser.parse_args()

    # Assigning the arguments to the respective variables
    mass = args.mass
    events = args.events
    process = args.process
    spin = args.spin
    seed_rnd = args.seed_rnd

    # Defining the model and generation command based on the given arguments
    model = 'mono_spin' + spin
    generate = 'a a >  mm+ mm-' if process == 'photon_fusion' else 'p p >  mm+ mm-'
    output_prefix = 'Spin' + spin.capitalize() + '_' + ('PF' if process == 'photon_fusion' else 'DY')
    output = f'{output_prefix}_{seed_rnd}'
    config_file = 'madgraph_config.txt'

    with open(config_file, 'w') as f:
        f.write('set auto_convert_model T\n')
        f.write(f'import model {model}\n')
        f.write(f'generate {generate}\n')
        f.write(f'output {output}\n')

    subprocess.run([MADGRAPH_PATH_RUN, config_file])

    # remove the config file
    os.remove(config_file)

    # save the current working directory
    cwd = os.getcwd()

    # change to the output directory
    os.chdir(output)

    # edit the file
    absolute_path = os.path.join(os.getcwd(), 'Source', 'maxparticles.inc')
    file_to_edit = 'Source/genps.inc'
    if os.path.isfile(file_to_edit):
        with fileinput.FileInput(file_to_edit, inplace=True) as file:
            for line in file:
                print(line.replace("'maxparticles.inc'", f"'{absolute_path}'"), end='')
    else:
        print(f'File {file_to_edit} not found!')

    # change back to the original directory
    os.chdir(cwd)

    # generate the events configuration file
    events_config_file = 'events_config.txt'
    with open(events_config_file, 'w') as f:
        f.write(f'launch {output}\n')
        f.write('analysis=madanalysis5\n' if process == 'photon_fusion' else 'analysis=madanalysis\n')
        f.write('set run_card ebeam1 6500.  ## energy per beam\n')
        f.write('set run_card ebeam2 6500\n')
        f.write('set run_card lpp1 1          ## lpp = 2 means elastic photon of proton/ion beam\n')
        f.write('set run_card lpp2 1\n')
        f.write('set run_card pdlabel lhapdf\n' if process == 'photon_fusion' else 'set run_card pdlabel nn23lo1\n')
        f.write('set run_card lhaid 324900\n' if process == 'photon_fusion' else 'set run_card lhaid 230000\n') 
        f.write(f'set run_card nevents {events}\n')
        f.write('set run_card dynamical_scale_choice -1\n')
        f.write(f'set run_card iseed {seed_rnd}\n')
        f.write('set run_card fixed_couplings False\n')
        f.write('set param_card mass 25 125\n')
        f.write(f'set param_card mass 4110000 {mass}  ### change the mass here\n')
        f.write('set param_card decay 4110000 0.000000e+0\n')
        f.write('set param_card gch 1 1.0\n')

    subprocess.run([MADGRAPH_PATH_RUN, events_config_file])

    # remove the events config file
    os.remove(events_config_file)

    # decompress the LHE file
    lhe_file = f'{output}/Events/run_01/unweighted_events.lhe.gz'
    with gzip.open(lhe_file, 'rb') as f_in:
        with open(f'{output}/Events/run_01/unweighted_events.lhe', 'wb') as f_out:
            shutil.copyfileobj(f_in, f_out)

    # remove the compressed LHE file
    os.remove(lhe_file)

    # rename and move the LHE file
    new_lhe_file = f'{output}_mass_{mass}_events_{events}.lhe'
    shutil.move(f'{output}/Events/run_01/unweighted_events.lhe', new_lhe_file)
    shutil.move(new_lhe_file, OUTPUT_DIR)

    # remove the output directory
    shutil.rmtree(output)

if __name__ == '__main__':
    main()
