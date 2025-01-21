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
    print("iSAFE data columns:", isafe_data.columns)  # Debugging print
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
    output_data['sim_id'] = sim_id
    output_data['sim_batch_no'] = simulation_serial_number
    cols = ['sim_batch_no', 'sim_id'] + [col for col in output_data.columns if col not in ['sim_batch_no', 'sim_id']]
    output_data = output_data[cols]
    
    # Save the output data to file with NA for missing values
    print(f"Saving output data to file: {output_file}")
    output_data.to_csv(output_file, sep='\t', index=False, na_rep='NA')

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

# Remove the individual tsv files after making the zip
print("Removing individual tsv files")
for file in files_to_zip:
    os.remove(file)
