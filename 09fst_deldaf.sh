#!/bin/bash
#SBATCH --partition=week
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8000

# Extract population IDs and pop1 from the config file
config_file="00config.json"
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
pop_ids=($(grep "^pop_define" $demographic_model | awk '{print $2}'))
simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selected_simulation_number"])')
pop1=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selective_sweep"].split()[3])')

echo "Starting FST and ΔDAF computation script..."
mkdir -p two_pop_stats
mkdir -p runtime

# Function to run FST and ΔDAF computations for pop1 versus other populations
run_fst_deldaf() {
    local sim_id=$1
    local pop1=$2
    
    echo "Processing simulation ID: $sim_id with pop1: $pop1"
    
    start_time=$(date +%s)
    Rscript 09compute_fst_deldaf.R "$sim_id" "$pop1" "${pop_ids[@]}"
    end_time=$(date +%s)
    runtime=$((end_time - start_time))
    echo "sim_id,$sim_id,fst_runtime,$runtime,seconds" >> runtime/fst.runtime.csv
}

# Function to monitor for new sim_ids and process them
monitor_new_sim_ids() {
    local prev_row_count=0
    local processed_sim_ids=()
    while true; do
        current_row_count=$(wc -l < runtime/nsl.sel.runtime.csv)
        if [ ${#processed_sim_ids[@]} -eq $((simulation_number + 1)) ]; then
            echo "All required TPED files have been processed and saved in the two_pop_stats directory."
            break
        fi
        
        new_sim_ids=$(tail -n +1 runtime/nsl.sel.runtime.csv | awk -F, 'NR > prev_row_count {print $2}' prev_row_count=$prev_row_count)
        for sim_id in $new_sim_ids; do
            if [[ ! " ${processed_sim_ids[@]} " =~ " ${sim_id} " ]]; then
                run_fst_deldaf $sim_id $pop1
                processed_sim_ids+=($sim_id)
            fi
        done
        
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

echo "Processed all fst. Exiting."
