import sys
import os
import pandas as pd
import matplotlib.pyplot as plt

def plot_xpehh(sim_id, pair_id):
    # File names
    norm_file = f"norm/temp.xpehh.{sim_id}_{pair_id}.tsv"
    hapbin_file = f"hapbin/temp.xpehh.{sim_id}_{pair_id}.tsv"
    
    # Read the data
    norm_data = pd.read_csv(norm_file, sep='\t')
    hapbin_data = pd.read_csv(hapbin_file, sep='\t')
    
    # Create the plot
    plt.figure(figsize=(10, 6))
    plt.scatter(norm_data['pos'], norm_data['norm_xpehh'], color='blue', label='norm')
    plt.scatter(hapbin_data['pos'], hapbin_data['norm_xpehh'], color='red', label='hapbin')
    
    # Add title and labels
    plt.title(f"xpehh {sim_id} {pair_id}")
    plt.xlabel('pos')
    plt.ylabel('norm_xpehh')
    plt.legend()
    
    # Save the plot
    output_dir = f"hapbin_vs_selscan"
    os.makedirs(output_dir, exist_ok=True)
    output_file = f"{output_dir}/xpehh.{sim_id}_{pair_id}.jpg"
    plt.savefig(output_file)
    
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <sim_id> <pair_id>")
        sys.exit(1)
    
    sim_id = sys.argv[1]
    pair_id = sys.argv[2]
    
    plot_xpehh(sim_id, pair_id)
