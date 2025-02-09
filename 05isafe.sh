#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8000

# Read inputs from JSON file using Python
config_file="00config.json"
selected_simulation_number=$(python3 -c "import json; print(json.load(open('$config_file'))['selected_simulation_number'])")
pop1=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selective_sweep"].split()[3])')

# Debugging output
echo "Selected Simulation Number: $selected_simulation_number"

# Create the one_pop_stats directory if it doesn't exist
mkdir -p one_pop_stats
mkdir -p runtime

# Function to run process_hap_and_run_isafe.py for a given simulation ID
run_isafe() {
    local sim_id=$1
    local tped_file="sel/sel.hap.${sim_id}_0_${pop1}.tped"
    echo "Processing $tped_file"
    start_time=$(date +%s)
    python 05process_hap_and_run_isafe.py "$sim_id"
    end_time=$(date +%s)
    runtime=$((end_time - start_time))
    echo "sim_id,$sim_id,isafe_runtime,$runtime,seconds" >> runtime/isafe.runtime.csv
}

# Function to monitor for new sim_ids and process them
monitor_new_sim_ids() {
    local prev_row_count=0
    local processed_sim_ids=()
    local last_mod_time=$(date +%s)
    while true; do
        current_row_count=$(wc -l < runtime/nsl.sel.runtime.csv)
        current_time=$(date +%s)
        
        if [ ${#processed_sim_ids[@]} -eq $((selected_simulation_number + 1)) ]; then
            echo "All required TPED files have been processed and saved in the one_pop_stats directory."
            break
        fi
        
        new_sim_ids=$(tail -n +1 runtime/nsl.sel.runtime.csv | awk -F, 'NR > prev_row_count {print $2}' prev_row_count=$prev_row_count)
        for sim_id in $new_sim_ids; do
            if [[ ! " ${processed_sim_ids[@]} " =~ " ${sim_id} " ]]; then
                run_isafe $sim_id
                processed_sim_ids+=($sim_id)
                last_mod_time=$(date +%s)  # Update last modification time
            fi
        done
        
        # Check if the file has not been modified for 30 minutes (1800 seconds)
        if (( current_time - last_mod_time > 1800 )); then
            echo "No new lines added to runtime/nsl.sel.runtime.csv for 30 minutes. Stopping script."
            break
        fi
        
        prev_row_count=$current_row_count
        sleep 5
    done
}

# Wait for the CSV file to be created
while [ ! -f runtime/nsl.sel.runtime.csv ]; do
    echo "Waiting for runtime/nsl.sel.runtime.csv to be created..."
    sleep 5
done

# Monitor and process new sim_ids
monitor_new_sim_ids

echo "Processed all isafe. Exiting."
