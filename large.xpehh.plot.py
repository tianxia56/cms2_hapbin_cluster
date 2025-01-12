import sys
import os
import pandas as pd
import matplotlib.pyplot as plt
import random

def plot_xpehh_combined():
    # Generate 50 random pairs of sim_id and pair_id
    sim_ids = random.sample(range(1000), 50)
    pair_ids = random.choices(['1_vs_2', '1_vs_3', '1_vs_4'], k=50)
    
    # Create a 5x10 subplot
    fig, axs = plt.subplots(5, 10, figsize=(20, 10))
    
    for i in range(5):
        for j in range(10):
            index = i * 10 + j
            sim_id = sim_ids[index]
            pair_id = pair_ids[index]
            
            # File names
            norm_file = f"norm/temp.xpehh.{sim_id}_{pair_id}.tsv"
            hapbin_file = f"hapbin/temp.xpehh.{sim_id}_{pair_id}.tsv"
            
            # Read the data
            norm_data = pd.read_csv(norm_file, sep='\t')
            hapbin_data = pd.read_csv(hapbin_file, sep='\t')
            
            # Create the scatter plot for the current subplot
            axs[i, j].scatter(norm_data['pos'], norm_data['norm_xpehh'], color='blue', alpha=0.3, s=0.1, label='norm', marker='o')
            axs[i, j].scatter(hapbin_data['pos'], hapbin_data['norm_xpehh'], color='red', alpha=0.9, s=0.01, label='hapbin', marker='o')
            
            # Set title and labels for the current subplot
            axs[i, j].set_title(f"xpehh {sim_id} {pair_id}")
            axs[i, j].set_xlabel('pos')
            axs[i, j].set_ylabel('norm_xpehh')
    
    # Adjust layout and save the combined plot
    plt.tight_layout()
    output_dir = "hapbin_vs_selscan"
    os.makedirs(output_dir, exist_ok=True)
    output_file = f"{output_dir}/xpehh_combined.jpg"
    plt.savefig(output_file)

if __name__ == "__main__":
    plot_xpehh_combined()
