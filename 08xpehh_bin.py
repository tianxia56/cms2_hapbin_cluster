import os
import numpy as np
import pandas as pd
import sys

def extract_columns(file_path, columns):
    """
    Extract specified columns from a file. If columns are missing, an exception is raised.
    """
    df = pd.read_csv(file_path, sep=r'\s+', header=None, engine='python')
    if df.shape[1] < max(columns) + 1:
        raise IndexError(f"File {file_path} does not have enough columns. Expected: {max(columns)+1}, Found: {df.shape[1]}")
    return df.iloc[:, columns]

def create_bins_and_stats(scores, dafs, num_bins=20):
    """
    Create bins and calculate statistics for scores based on derived allele frequencies (DAFs).
    Bins are created based on the distribution of DAFs.
    """
    dafs = pd.to_numeric(dafs, errors='coerce')
    scores = pd.to_numeric(scores, errors='coerce')
    valid_indices = ~np.isnan(dafs) & ~np.isnan(scores)
    dafs = dafs[valid_indices]
    scores = scores[valid_indices]
    
    # Sort the dataframe by daf
    sorted_indices = np.argsort(dafs)
    dafs = dafs.iloc[sorted_indices]
    scores = scores.iloc[sorted_indices]
    
    # Calculate bin edges based on the distribution of daf
    bin_edges = np.linspace(dafs.min(), dafs.max(), num_bins + 1)
    
    bin_means = []
    bin_stds = []
    for i in range(len(bin_edges) - 1):
        bin_scores = scores[(dafs >= bin_edges[i]) & (dafs < bin_edges[i + 1])]

        if len(bin_scores) > 0:
            bin_means.append(bin_scores.mean())
            bin_stds.append(bin_scores.std())
        else:
            bin_means.append(np.nan)
            bin_stds.append(np.nan)
    return bin_edges, bin_means, bin_stds

# Ensure the 'norm' directory exists
os.makedirs('norm', exist_ok=True)

# Check if the required arguments are provided
if len(sys.argv) < 3:
    print("Usage: python make_xpehh_bin.py <sim_id> <pair_ids>")
    sys.exit(1)

# Read command-line arguments
sim_id = sys.argv[1]
pair_ids = sys.argv[2].split(',')

# Initialize lists to store combined data
combined_xpehh = {pair_id: [] for pair_id in pair_ids}

# Loop through each pair_id and extract data
for pair_id in pair_ids:
    xpehh_file_path = f'hapbin/neut.{sim_id}_{pair_id}.xpehh.out'
    if not os.path.exists(xpehh_file_path):
        print(f"File not found: {xpehh_file_path}")
        continue
    try:
        xpehh_df = extract_columns(xpehh_file_path, [0, 1, 2])
        combined_xpehh[pair_id].append(xpehh_df)
    except IndexError as e:
        print(f"Skipping xpehh file {xpehh_file_path} due to error: {e}")
        continue

# Process and save xpehh data for each pair_id
for pair_id in pair_ids:
    if combined_xpehh[pair_id]:
        combined_xpehh_df = pd.concat(combined_xpehh[pair_id])
        bins_xpehh, means_xpehh, stds_xpehh = create_bins_and_stats(combined_xpehh_df.iloc[:, 2], combined_xpehh_df.iloc[:, 1])
        pd.DataFrame({'bin': bins_xpehh[:-1], 'mean': means_xpehh, 'std': stds_xpehh}).to_csv(f'bin/xpehh_{pair_id}_bin.csv', index=False)

print("xpehh bin files have been successfully saved in the 'norm' directory.")
