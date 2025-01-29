import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import zipfile
import os

# Initialize an empty DataFrame to store the combined data
combined_data = pd.DataFrame()

# Define the base directory pattern
base_directory_pattern = 'run_10_cms_jobs/run_cms2_take*/output'

# Iterate over all directories that match the pattern
for i in range(2, 8):
    directory = base_directory_pattern.replace('*', str(i))
    if os.path.exists(directory):
        # Iterate over all zip files in the directory that match the pattern
        for filename in os.listdir(directory):
            if filename.endswith('.tsv.zip'):
                zip_file_path = os.path.join(directory, filename)
                with zipfile.ZipFile(zip_file_path, 'r') as z:
                    # Assuming there is only one file in each zip
                    tsv_file_name = z.namelist()[0]
                    with z.open(tsv_file_name) as f:
                        data = pd.read_csv(f, sep='\t')
                        combined_data = pd.concat([combined_data, data], ignore_index=True)

# Get the row count of the combined data
row_count = combined_data.shape[0]

# Create the first scatter plot with histograms
plt.figure(figsize=(10, 6))
scatter1 = sns.jointplot(x='s', y='daf', data=combined_data, kind='scatter', marginal_kws=dict(bins=50, fill=True), edgecolor=None, s=10)
scatter1.set_axis_labels('Selection Coefficient', 'Derived Allele Frequency')
scatter1.ax_joint.set_xlim(0, 0.5)
plt.suptitle(f'N={row_count}', y=1.02)
scatter1.savefig('scatter_plot1.png')
plt.close()

# Create the second scatter plot with histograms
plt.figure(figsize=(10, 6))
scatter2 = sns.jointplot(x='sel_gen', y='daf', data=combined_data, kind='scatter', marginal_kws=dict(bins=50, fill=True), edgecolor=None, s=10)
scatter2.set_axis_labels('Generations under selection', 'Derived Allele Frequency')
scatter2.ax_joint.set_xlim(0, 5000)
plt.suptitle(f'N={row_count}', y=1.02)
scatter2.savefig('scatter_plot2.png')
plt.close()

print("Plots saved successfully.")
