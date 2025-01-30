import json
import os
import pandas as pd
from datetime import datetime
import zipfile

# Define variables
config_file = "00config.json"
with open(config_file, 'r') as f:
    config = json.load(f)
demographic_model = config['demographic_model']
simulation_serial_number = config['simulation_serial_number']
pos_sel_rows = 1500000

# Read sim_id values from the second column of runtime/nsl.sel.runtime.csv, including the first row
sim_ids = pd.read_csv("runtime/nsl.sel.runtime.csv", header=None).iloc[:, 1]

# Define output directory
output_dir = "output"
if not os.path.exists(output_dir):
    os.makedirs(output_dir)

# Function to collate stats
def collate_stats(sim_id, demographic_model, simulation_serial_number):
    output_file = f"{output_dir}/{demographic_model}_batch{simulation_serial_number}_cms_stats_{sim_id}.tsv"
    print(f"Processing simulation ID: {sim_id}")
    
    # Read fst_deldaf file
    fst_deldaf_file = f"two_pop_stats/{sim_id}_fst_deldaf.tsv"
    fst_deldaf_data = pd.read_csv(fst_deldaf_file, sep='\t')
    
    # Initialize output data with fst_deldaf data
    output_data = fst_deldaf_data
    
    # Read iSAFE file and merge
    isafe_file = f"one_pop_stats/{sim_id}.iSAFE.out"
    isafe_data = pd.read_csv(isafe_file, sep='\t')
    isafe_data.rename(columns={'POS': 'pos'}, inplace=True)
    isafe_data['iSAFE'] = isafe_data['iSAFE'].round(4)  # Round iSAFE to 4 significant figures
    output_data = pd.merge(output_data, isafe_data[['pos', 'iSAFE']], on='pos', how='outer')
    
    # Read norm_ihs file and merge
    norm_ihs_file = f"norm/temp.ihs.{sim_id}.tsv"
    norm_ihs_data = pd.read_csv(norm_ihs_file, sep='\t')
    output_data = pd.merge(output_data, norm_ihs_data[['pos', 'norm_ihs']], on='pos', how='outer')
    
    # Read norm_nsl file and merge
    norm_nsl_file = f"norm/temp.nsl.{sim_id}.tsv"
    norm_nsl_data = pd.read_csv(norm_nsl_file, sep='\t')
    output_data = pd.merge(output_data, norm_nsl_data[['pos', 'norm_nsl']], on='pos', how='outer')
    
    # Read norm_ihh12 file and merge
    norm_ihh12_file = f"norm/temp.ihh12.{sim_id}.tsv"
    norm_ihh12_data = pd.read_csv(norm_ihh12_file, sep='\t')
    output_data = pd.merge(output_data, norm_ihh12_data[['pos', 'norm_ihh12']], on='pos', how='outer')
    
    # Read norm_delihh file and merge
    norm_delihh_file = f"norm/temp.delihh.{sim_id}.tsv"
    norm_delihh_data = pd.read_csv(norm_delihh_file, sep='\t')
    output_data = pd.merge(output_data, norm_delihh_data[['pos', 'norm_delihh']], on='pos', how='outer')
    
    # Read norm_max_xpehh file and merge
    norm_max_xpehh_file = f"norm/temp.max.xpehh.{sim_id}.tsv"
    norm_max_xpehh_data = pd.read_csv(norm_max_xpehh_file, sep='\t')
    output_data = pd.merge(output_data, norm_max_xpehh_data[['pos', 'max_xpehh']], on='pos', how='outer')
    
    # Add sim_id and sim_batch_no as the first columns
    output_data['sim_batch_no'] = simulation_serial_number
    output_data['sim_id'] = sim_id
    cols = ['sim_batch_no', 'sim_id'] + [col for col in output_data.columns if col not in ['sim_batch_no', 'sim_id']]
    output_data = output_data[cols]
    
    # Save the output data to file with NA for missing values
    print(f"Saving output data to file: {output_file}")
    output_data.to_csv(output_file, sep='\t', index=False, na_rep='NA')

# Function to save rows with pos_sel_rows to TSV
def save_pos_sel_rows_to_tsv(sim_id, demographic_model, simulation_serial_number):
    input_file = f"{output_dir}/{demographic_model}_batch{simulation_serial_number}_cms_stats_{sim_id}.tsv"
    
    current_date = datetime.now().strftime("%Y-%m-%d")
    output_file = f"{output_dir}/{demographic_model}_batch{simulation_serial_number}_par_inputs_{current_date}.tsv"
    
    if not os.path.exists(input_file):
        print(f"File not found: {input_file}")
        return
    
    data = pd.read_csv(input_file, sep='\t')
    
    if 'pos' not in data.columns:
        print(f"'pos' column not found in file: {input_file}")
        return
    
    pos_sel_rows_data = data[data['pos'] == pos_sel_rows]
    
    if pos_sel_rows_data.empty:
        print(f"No rows with pos={pos_sel_rows} found in file: {input_file}")
        return
    
    if not os.path.exists(output_file):
        pos_sel_rows_data.to_csv(output_file, sep='\t', index=False, na_rep='NA')
    else:
        pos_sel_rows_data.to_csv(output_file, mode='a', header=False, index=False, sep='\t')
# Function to process cosi.sel.*.csv files and round up the numbers
def process_cosi_sel_files():
    current_date = datetime.now().strftime("%Y-%m-%d")
    par_inputs_file = f"{output_dir}/{demographic_model}_batch{simulation_serial_number}_par_inputs_{current_date}.tsv"
    
    for i in range(1, 6):
        cosi_file = f"runtime/cosi.sel.{i}.csv"
        if not os.path.exists(cosi_file):
            print(f"File not found: {cosi_file}")
            continue
        
        cosi_data = pd.read_csv(cosi_file, header=None, sep=' ')
        
        if cosi_data.shape[1] != 9:
            print(f"Unexpected number of columns in {cosi_file}")
            continue
        
        cosi_data.columns = ['command', 'param1', 'param2', 'param3', 'param4', 'param5', 'param6', 'param7', 'param8']
        
        # Filter rows with 'sweep' command and single number in the next row
        sweep_rows = cosi_data[cosi_data['command'].str.startswith('sweep')]
        for idx, row in sweep_rows.iterrows():
            if idx + 1 < len(cosi_data) and cosi_data.iloc[idx + 1, 0].isdigit():
                sim_id = int(cosi_data.iloc[idx + 1, 0])
                deri_gen = int(round(float(row['param3'])))  # Corrected column index and rounded to integer
                sel_gen = int(round(float(row['param8'])))
                s = row['param4']
                
                # Append to par_inputs_file
                if os.path.exists(par_inputs_file):
                    par_inputs_data = pd.read_csv(par_inputs_file, sep='\t')
                    par_inputs_data.loc[par_inputs_data['sim_id'] == sim_id, ['deri_gen', 'sel_gen', 's']] = [deri_gen, sel_gen, s]
                    par_inputs_data.to_csv(par_inputs_file, sep='\t', index=False, na_rep='NA')
                else:
                    print(f"File not found: {par_inputs_file}")

# Loop through simulations and populations
for sim_id in sim_ids:
    with open(demographic_model, 'r') as f:
        pop_ids = [line.split()[1] for line in f if line.startswith("pop_define")]
    
    for i in range(len(pop_ids)):
        for j in range(i + 1, len(pop_ids)):
            pop1 = pop_ids[i]
            pop2 = pop_ids[j]
            pair_id = f"{pop1}_vs_{pop2}"
            # Here you would call the make_max_xpehh function in Python
            # make_max_xpehh(sim_id, pair_id)
    
    # Call collate_stats function
    collate_stats(sim_id, demographic_model, simulation_serial_number)
    
    # Call save_pos_sel_rows_to_tsv function
    save_pos_sel_rows_to_tsv(sim_id, demographic_model, simulation_serial_number)

# Process cosi.sel.*.csv files
process_cosi_sel_files()

# Append additional parameters to the final TSV files
def append_additional_parameters():
    current_date = datetime.now().strftime("%Y-%m-%d")
    par_inputs_file = f"{output_dir}/{demographic_model}_batch{simulation_serial_number}_par_inputs_{current_date}.tsv"
    
    if not os.path.exists(par_inputs_file):
        print(f"File not found: {par_inputs_file}")
        return
    
    par_inputs_data = pd.read_csv(par_inputs_file, sep='\t')
    
    for sim_id in sim_ids:
        output_file = f"{output_dir}/{demographic_model}_batch{simulation_serial_number}_cms_stats_{sim_id}.tsv"
        if not os.path.exists(output_file):
            print(f"File not found: {output_file}")
            continue
        
        output_data = pd.read_csv(output_file, sep='\t')
        
        if 'sim_id' not in output_data.columns:
            print(f"'sim_id' column not found in file: {output_file}")
            continue
        
        additional_params = par_inputs_data[par_inputs_data['sim_id'] == sim_id][['deri_gen', 'sel_gen', 's']]
        if additional_params.empty:
            print(f"No additional parameters found for sim_id={sim_id}")
            continue
        
        additional_params = additional_params.iloc[0]
        output_data['deri_gen'] = additional_params['deri_gen']
        output_data['sel_gen'] = additional_params['sel_gen']
        output_data['s'] = f"{additional_params['s']:.2e}"  # Format s in scientific notation with 2 significant figures
        
        output_data.to_csv(output_file, sep='\t', index=False, na_rep='NA')

# Append additional parameters to the final TSV files
append_additional_parameters()

# Zip all the output files into one single tsv zip with the current date in the name using higher compression rate
current_date = datetime.now().strftime("%Y-%m-%d")
zipfile_name = f"{output_dir}/{demographic_model}_batch{simulation_serial_number}_cms_stats_all_{current_date}.zip"
print(f"Creating zip file: {zipfile_name}")

# List files to zip
files_to_zip = [os.path.join(output_dir, f) for f in os.listdir(output_dir) if f.startswith(f"{demographic_model}_batch{simulation_serial_number}_cms_stats_") and f.endswith(".tsv")]

# Print the files to zip for debugging
print("Files to zip:")
print(files_to_zip)

# Check if files_to_zip is empty
if not files_to_zip:
    raise Exception("No files found to zip. Please check the output directory and file pattern.")

# Create the zip file with higher compression rate (ZIP_DEFLATED)
with zipfile.ZipFile(zipfile_name, 'w', compression=zipfile.ZIP_DEFLATED) as zipf:
    for file in files_to_zip:
        zipf.write(file, os.path.basename(file))

# Print completion message
print("Zip file created successfully")

# Zip the par_inputs TSV file separately
current_date = datetime.now().strftime("%Y-%m-%d")
par_inputs_file = f"{output_dir}/{demographic_model}_batch{simulation_serial_number}_par_inputs_{current_date}.tsv"
par_inputs_zipfile_name = f"{par_inputs_file}.zip"
print(f"Creating zip file for par_inputs: {par_inputs_zipfile_name}")

if os.path.exists(par_inputs_file):
    with zipfile.ZipFile(par_inputs_zipfile_name, 'w', compression=zipfile.ZIP_DEFLATED) as zipf:
        zipf.write(par_inputs_file, os.path.basename(par_inputs_file))
    # Print completion message for par_inputs zip
    print("Par inputs zip file created successfully")
else:
    print(f"File not found: {par_inputs_file}")

# Remove the individual tsv files after making the zip
print("Removing individual tsv files")
for file in os.listdir(output_dir):
    if file.endswith(".tsv"):
        os.remove(os.path.join(output_dir, file))
