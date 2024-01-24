import os
import re

# Função para encontrar arquivos faltando
def find_missing_files(input_directory, input_pattern, output_directory, output_template, mass_values):
    missing_files = []
    for mass in mass_values:
        # Atualiza o padrão de entrada e saída com o valor de massa atual
        current_input_pattern = input_pattern.format(mass)
        current_output_pattern = output_template.format(mass)

        # Lista todos os arquivos no diretório
        all_files = os.listdir(input_directory)

        # Filtra arquivos baseados no padrão atual
        filtered_files = [f for f in all_files if re.match(current_input_pattern, f)]

        # Extrai os números de sequência dos nomes dos arquivos
        sequence_numbers = [int(re.search(r'PF_(\d+)_', f).group(1)) for f in filtered_files]

        # Encontra os números de sequência faltando
        missing_numbers = [i for i in range(1, max(sequence_numbers) + 1) if i not in sequence_numbers]

        # Gera os nomes dos arquivos faltando com caminho completo e extensão modificada
        missing_files.extend([current_output_pattern.format(i) for i in missing_numbers])

    return missing_files

# Define o diretório, padrão de entrada e saída, e valores de massa
input_directory = '/eos/home-m/matheus/magnetic_monopole_output_AOD/'
output_directory = '/eos/home-m/matheus/magnetic_monopole_output'
mass_values = [200, 500, 1000, 1500, 2000, 2500, 3000]
input_pattern = r'SpinHalf_PF_\d+_mass_{}_events_500_AOD.root'
output_template = output_directory + "/SpinHalf_PF_{}_mass_{}_events_500.lhe"

# Encontra os arquivos faltando para cada valor de massa
missing_files = find_missing_files(input_directory, input_pattern, output_directory, output_template, mass_values)

# Escreve os arquivos faltando em um arquivo de texto
output_file_path = '/afs/cern.ch/user/m/matheus/CMSSW_10_6_23/src/failed_jobs.txt'
with open(output_file_path, 'w') as f:
    for file in missing_files:
        f.write(f"{file}\n")

print(f"Arquivos faltando foram escritos em {output_file_path}\n")
print(missing_files)

