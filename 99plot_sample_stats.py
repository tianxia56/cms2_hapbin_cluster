import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import re
import zipfile
import os
import random

# Define the zip file path
zip_file_path = 'output/jv_default_112115_825am.par_batch10086_cms_stats_all_2025-01-28.zip'

# List all TSV files in the zip archive
with zipfile.ZipFile(zip_file_path, 'r') as z:
    tsv_files = [f for f in z.namelist() if f.endswith('.tsv')]

# Select a random TSV file from the list
random_tsv_file = random.choice(tsv_files)

# Extract the dynamic name, batch_id, and sim_id from the selected TSV file name using regex
match = re.match(r'(.*)_batch(\d+)_cms_stats_(\d+)\.tsv', random_tsv_file)
if match:
    dynamic_name = match.group(1)
    batch_id = match.group(2)
    sim_id = match.group(3)
else:
    raise ValueError("Could not extract dynamic name, batch_id, and sim_id from the TSV file name")

# Load the data from the selected TSV file
with zipfile.ZipFile(zip_file_path, 'r') as z:
    with z.open(random_tsv_file) as f:
        data = pd.read_csv(f, sep='\t')

# Rename the columns in the DataFrame
data.rename(columns={
    'mean_fst': 'Fst',
    'deldaf': 'ΔDAF',
    'norm_ihs': 'iHS',
    'norm_nsl': 'nSL',
    'norm_ihh12': 'iHH12',
    'norm_delihh': 'ΔiHH',
    'max_xpehh': 'XPEHH'
}, inplace=True)

# Define the columns to plot (excluding 'maf' and 'daf')
columns_to_plot = ['Fst', 'ΔDAF', 'iSAFE', 'iHS', 'nSL', 'iHH12', 'ΔiHH', 'XPEHH']

# Debugging: Print the first few rows of the data
print("Data (first few rows):")
print(data.head())

# Debugging: Print the values extracted from each column
for column in columns_to_plot:
    print(f"Values for {column} (first few rows):")
    print(data[column].head())

# Create a combined plot with shared x-axis and 16:9 aspect ratio
fig, axes = plt.subplots(len(columns_to_plot), 1, figsize=(16, 9), sharex=True)

for i, column in enumerate(columns_to_plot):
    sns.scatterplot(x='pos', y=column, data=data, ax=axes[i], color='black', s=10, edgecolor=None)
    axes[i].set_ylabel(column, rotation=0, labelpad=40, fontsize=16)
    axes[i].tick_params(axis='y', which='both', length=0)  # Remove y-axis ticks
    axes[i].spines['top'].set_visible(False)
    axes[i].spines['right'].set_visible(False)
    axes[i].spines['left'].set_visible(False)

axes[-1].set_xlabel('Position', fontsize=18)
axes[-1].ticklabel_format(style='plain', axis='x')  # Avoid scientific notation

plt.suptitle(f'{dynamic_name} - batch_id: {batch_id} - sim_id: {sim_id}', fontsize=20)
plt.tight_layout(rect=[0, 0.03, 1, 0.95], h_pad=1)  # Adjust gaps between plots

# Save the combined plot to a file
output_plot_path = f'output/{dynamic_name}_batch{batch_id}_{sim_id}.png'
plt.savefig(output_plot_path)
plt.close()

print(f"Combined plot saved to {output_plot_path}")
