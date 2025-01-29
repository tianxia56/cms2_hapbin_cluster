import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import re
import zipfile
import os

# Define the directory containing the zip files
directory = 'output'

# Initialize an empty DataFrame to store the combined data
combined_data = pd.DataFrame()

# Iterate over all zip files in the directory that match the pattern
for filename in os.listdir(directory):
    match = re.match(r'(.*)_batch.*_par_inputs_.*\.tsv\.zip', filename)
    if match:
        dynamic_name = match.group(1)
        zip_file_path = os.path.join(directory, filename)
        with zipfile.ZipFile(zip_file_path, 'r') as z:
            # Assuming there is only one file in each zip
            tsv_file_name = z.namelist()[0]
            with z.open(tsv_file_name) as f:
                data = pd.read_csv(f, sep='\t')
                combined_data = pd.concat([combined_data, data], ignore_index=True)

# Create the first scatter plot with histograms
plt.figure(figsize=(10, 6))
scatter1 = sns.jointplot(x='s', y='daf', data=combined_data, kind='scatter', marginal_kws=dict(bins=50, fill=True))
scatter1.set_axis_labels('Selection Coefficient', 'Derived Allele Frequency')
scatter1.ax_joint.set_xlim(0, 0.5)
plt.suptitle(f'{dynamic_name}', y=1.02)
scatter1.savefig(f'output/{dynamic_name}_scatter_plot1.png')
plt.close()

# Create the second scatter plot with histograms
plt.figure(figsize=(10, 6))
scatter2 = sns.jointplot(x='sel_gen', y='daf', data=combined_data, kind='scatter', marginal_kws=dict(bins=50, fill=True))
scatter2.set_axis_labels('Generations under selection', 'Derived Allele Frequency')
scatter2.ax_joint.set_xlim(0, 5000)
plt.suptitle(f'{dynamic_name}', y=1.02)
scatter2.savefig(f'output/{dynamic_name}_scatter_plot2.png')
plt.close()

print("Plots saved successfully.")
