import os
import pandas as pd

def add_id_pos_and_daf_column(sim_id, pop1, path):
    # Read the ID and position columns (2nd and 4th columns) as id and pos
    tped_file = f"{path}/{path}.hap.{sim_id}_0_{pop1}.tped"
    tped_data = pd.read_csv(tped_file, sep='\\s+', usecols=[1, 3], header=None)
    tped_data.columns = ['ID', 'pos']
    
    # Read the genetic data (5th column onward) for pop1
    pop_data = pd.read_csv(tped_file, sep='\\s+', usecols=range(4, len(pd.read_csv(tped_file, sep='\\s+', nrows=1).columns)), header=None)
    
    # Compute derived allele frequency (DAF) for pop1
    daf = pop_data.mean(axis=1)
    
    # Ensure DAF is numeric
    daf = pd.to_numeric(daf, errors='coerce')
    
    # Create a results table using the IDs and positions from the TPED file
    results = pd.DataFrame({'ID': tped_data['ID'], 'pos': tped_data['pos'], 'daf': daf})
    
    return results

def inner_join_with_xpehh(sim_id, pop1, max_pop_id, path):
    # Add ID, pos and daf columns to the output files
    results = add_id_pos_and_daf_column(sim_id, pop1, path)
    
    # Perform an inner join with the xpehh.out file by ID
    for pop2 in range(1, max_pop_id+1):
        if pop2 != int(pop1):
            xpehh_file = f"hapbin/{path}.{sim_id}_{pop1}_vs_{pop2}.xpehh.out"
            if os.path.exists(xpehh_file):
                xpehh_data = pd.read_csv(xpehh_file, sep='\\s+', usecols=[1, 6], header=0)
                
                # Rename columns to avoid spaces
                xpehh_data.columns = ['ID', 'xpehh']
                
                # Ensure xpehh is numeric
                xpehh_data['xpehh'] = pd.to_numeric(xpehh_data['xpehh'], errors='coerce')
                
                # Debugging: Check if 'ID' column exists in both DataFrames
                if 'ID' not in xpehh_data.columns:
                    print(f"ERROR: 'ID' column not found in {xpehh_file}")
                    continue
                if 'ID' not in results.columns:
                    print(f"ERROR: 'ID' column not found in results DataFrame")
                    continue
                
                merged_data = pd.merge(xpehh_data, results[['ID', 'pos', 'daf']], on='ID', how='inner')
                
                # Keep only the columns pos, daf, and xpehh in the output
                final_data = merged_data[['pos', 'daf', 'xpehh']]
                
                final_data.to_csv(xpehh_file, sep=' ', index=False)
                print(f"Updated {xpehh_file} with pos, daf, and xpehh columns.")

def remove_map_and_hap_files(sim_id, pop_ids, path):
    for pop_id in pop_ids:
        hap_file = f"hapbin/{path}.{sim_id}_0_{pop_id}.hap"
        map_file = f"hapbin/{path}.{sim_id}_0_{pop1}.map"
        if os.path.exists(hap_file):
            os.remove(hap_file)
            print(f"Removed {hap_file}")
        if os.path.exists(map_file):
            os.remove(map_file)
            print(f"Removed {map_file}")

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 5:
        print("Usage: python add_xpehh_daf.py <sim_id> <pop1> <max_pop_id> <path>")
        sys.exit(1)
    
    sim_id = int(sys.argv[1])
    pop1 = int(sys.argv[2])
    max_pop_id = int(sys.argv[3])
    path = sys.argv[4]
    
    inner_join_with_xpehh(sim_id, pop1, max_pop_id, path)
    
    # Remove map and hap files after making the output
    remove_map_and_hap_files(sim_id, range(1, max_pop_id+1), path)
