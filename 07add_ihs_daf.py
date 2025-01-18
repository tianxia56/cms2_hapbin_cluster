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

def inner_join_with_ihs(sim_id, pop1, path):
    # Add ID, pos and daf columns to the output files
    results = add_id_pos_and_daf_column(sim_id, pop1, path)
    
    # Ensure 'ID' column in results is of type string
    results['ID'] = results['ID'].astype(str)
    
    # Perform an inner join with the ihs.out file by ID
    ihs_file = f"hapbin/{path}.hap.{sim_id}_0_{pop1}.ihs.out"
    print(f"Reading IHS file: {ihs_file}")
    if os.path.exists(ihs_file):
        ihs_data = pd.read_csv(ihs_file, sep='\\s+', header=None, usecols=[1, 2, 3, 4, 5, 6])
        
        # Rename columns to avoid spaces
        ihs_data.columns = ['ID', 'Freq', 'iHH_0', 'iHH_1', 'iHS', 'Std_iHS']
        
        # Ensure 'ID' column in ihs_data is of type string
        ihs_data['ID'] = ihs_data['ID'].astype(str)
        
        # Ensure iHH_0, iHH_1, and iHS are numeric
        ihs_data['iHH_0'] = pd.to_numeric(ihs_data['iHH_0'], errors='coerce')
        ihs_data['iHH_1'] = pd.to_numeric(ihs_data['iHH_1'], errors='coerce')
        ihs_data['iHS'] = pd.to_numeric(ihs_data['iHS'], errors='coerce')
        
        # Compute delihh as the difference between iHH_1 and iHH_0
        ihs_data['delihh'] = ihs_data['iHH_1'] - ihs_data['iHH_0']
        
        # Debugging: Check if 'ID' column exists in both DataFrames
        if 'ID' not in ihs_data.columns:
            print(f"ERROR: 'ID' column not found in {ihs_file}")
            return
        if 'ID' not in results.columns:
            print(f"ERROR: 'ID' column not found in results DataFrame")
            return
        
        merged_data = pd.merge(ihs_data, results[['ID', 'pos', 'daf']], on='ID', how='inner')
        
        # Keep only the columns pos, daf, iHS and delihh in the output
        final_data = merged_data[['pos', 'daf', 'iHS', 'delihh']]
        
        # Ensure the output directory exists
        output_dir = "one_pop_stats"
        os.makedirs(output_dir, exist_ok=True)
        
        # Save the final data to the new directory
        output_file = f"{output_dir}/{path}.{sim_id}_0_{pop1}.ihs.out"
        final_data.to_csv(output_file, sep=' ', index=False)
        print(f"Updated {output_file} with pos, daf, iHS and delihh columns.")
    else:
        print(f"ERROR: IHS file {ihs_file} does not exist.")

if __name__ == "__main__":
    import sys
    if len(sys.argv) != 4:
        print("Usage: python add_ihs_daf.py <sim_id> <pop1> <path>")
        sys.exit(1)
    
    sim_id = int(sys.argv[1])
    pop1 = int(sys.argv[2])
    path = sys.argv[3]
    
    inner_join_with_ihs(sim_id, pop1, path)
