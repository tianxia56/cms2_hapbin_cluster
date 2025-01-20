import os
import pandas as pd
import numpy as np
import sys

# Get sim_ids from command line arguments
sim_ids = list(map(int, sys.argv[1].split(',')))

# Function to read and process nsl files
def process_nsl(file_path):
    df = pd.read_csv(file_path, sep='\t', header=None, names=['ID', 'pos', 'p1', 'sl1', 'sl0', 'nsl'], skiprows=1)
    df['p1'] = pd.to_numeric(df['p1'], errors='coerce')  # Ensure 'p1' is float
    return df[['pos', 'p1', 'nsl']].rename(columns={'p1': 'daf'})

# Function to read and process ihs files
def process_ihs(file_path):
    df = pd.read_csv(file_path, sep=' ', header=None, names=['pos', 'daf', 'iHS', 'delihh'], skiprows=1)
    df['daf'] = pd.to_numeric(df['daf'], errors='coerce')  # Ensure 'daf' is float
    return df[['pos', 'daf', 'iHS']], df[['pos', 'daf', 'delihh']]

# Function to read and process ihh12 files
def process_ihh12(file_path):
    df = pd.read_csv(file_path, sep='\t', header=None, names=['id', 'pos', 'p1', 'ihh12'], skiprows=1)
    df['p1'] = pd.to_numeric(df['p1'], errors='coerce')  # Ensure 'p1' is float
    return df[['pos', 'p1', 'ihh12']].rename(columns={'p1': 'daf'})

# Function to bin data and calculate mean and std based on the distribution of daf
def bin_data(df, value_col, num_bins=20):
    # Sort the dataframe by daf
    df = df.sort_values(by='daf')
    
    # Calculate bin edges based on the distribution of daf
    bin_edges = np.linspace(df['daf'].min(), df['daf'].max(), num_bins + 1)
    
    # Assign each row to a bin
    df['bin'] = pd.cut(df['daf'], bins=bin_edges, include_lowest=True)
    
    # Calculate mean and std for each bin
    binned = df.groupby('bin', observed=True)[value_col].agg(['mean', 'std']).reset_index()
    
    # Extract the right edge of each bin for labeling
    binned['bin'] = binned['bin'].apply(lambda x: x.right)
    
    return binned

# Initialize empty dataframes for concatenation
nsl_data = pd.DataFrame()
ihs_data = pd.DataFrame()
delihh_data = pd.DataFrame()
ihh12_data = pd.DataFrame()

# Process files for all passed sim_ids and row bind them
for sim_id in sim_ids:
    nsl_file = f'one_pop_stats/neut.{sim_id}.nsl.out'
    ihs_file = f'one_pop_stats/neut.{sim_id}_0_1.ihs.out'
    ihh12_file = f'one_pop_stats/neut.{sim_id}.ihh12.out'

    if os.path.exists(nsl_file):
        nsl_data = pd.concat([nsl_data, process_nsl(nsl_file)], ignore_index=True)
    
    if os.path.exists(ihs_file):
        ihs_df, delihh_df = process_ihs(ihs_file)
        ihs_data = pd.concat([ihs_data, ihs_df], ignore_index=True)
        delihh_data = pd.concat([delihh_data, delihh_df], ignore_index=True)
    
    if os.path.exists(ihh12_file):
        ihh12_data = pd.concat([ihh12_data, process_ihh12(ihh12_file)], ignore_index=True)

# Drop rows with NaN values in the daf column
nsl_data.dropna(subset=['daf'], inplace=True)
ihs_data.dropna(subset=['daf'], inplace=True)
delihh_data.dropna(subset=['daf'], inplace=True)
ihh12_data.dropna(subset=['daf'], inplace=True)

# Bin data and calculate mean and std based on the distribution of daf for each dataset separately
nsl_binned = bin_data(nsl_data, 'nsl')
ihs_binned = bin_data(ihs_data, 'iHS')
delihh_binned = bin_data(delihh_data, 'delihh')
ihh12_binned = bin_data(ihh12_data, 'ihh12')

# Save binned data to files
os.makedirs('bin', exist_ok=True)
nsl_binned.to_csv(f'bin/nsl_bin.csv', index=False)
ihs_binned.to_csv(f'bin/ihs_bin.csv', index=False)
delihh_binned.to_csv(f'bin/delihh_bin.csv', index=False)
ihh12_binned.to_csv(f'bin/ihh12_bin.csv', index=False)

print(f"Binned data saved to the 'bin' directory for sim_ids {sim_ids}.")
