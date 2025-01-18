#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=8000

# Read inputs from JSON file using Python
config_file="00config.json"
neutral_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["neutral_simulation_number"])')
path="neut"

# Create the one_pop_stats directory if it doesn't exist
mkdir -p one_pop_stats
mkdir -p runtime

# Function to run selscan commands for a given TPED file
run_selscan() {
    local sim_id=$1
    local tped_file="${path}/${path}.hap.${sim_id}_0_1.tped"
    local base_name="${path}.${sim_id}"
    
    start_time=$(date +%s)
    selscan --nsl --tped $tped_file --out one_pop_stats/$base_name --threads 4
    end_time=$(date +%s)
    runtime=$((end_time - start_time))
    echo "sim_id,$sim_id,nsl_runtime,$runtime,seconds" >> runtime/nsl.${path}.runtime.csv
    
    start_time=$(date +%s)
    selscan --ihh12 --tped $tped_file --out one_pop_stats/$base_name --threads 4
    end_time=$(date +%s)
    runtime=$((end_time - start_time))
    echo "sim_id,$sim_id,ihh12_runtime,$runtime,seconds" >> runtime/ihh12.${path}.runtime.csv
}

# Function to monitor for new sim_ids and process them
monitor_new_sim_ids() {
    local prev_row_count=0
    local processed_sim_ids=()
    while true; do
        current_row_count=$(wc -l < runtime/cosi.${path}.runtime.csv)
        if [ ${#processed_sim_ids[@]} -eq $((neutral_simulation_number + 1)) ]; then
            echo "nsl and ihh12 ${path} have been calculated and saved in the one_pop_stats directory."
            break
        fi
        
        new_sim_ids=$(tail -n +1 runtime/cosi.${path}.runtime.csv | awk -F, 'NR > prev_row_count {print $2}' prev_row_count=$prev_row_count)
        for sim_id in $new_sim_ids; do
            if [[ ! " ${processed_sim_ids[@]} " =~ " ${sim_id} " ]]; then
                run_selscan $sim_id
                processed_sim_ids+=($sim_id)
            fi
        done
        
        prev_row_count=$current_row_count
        sleep 5
    done
}

# Wait for the CSV file to be created
while [ ! -f runtime/cosi.${path}.runtime.csv ]; do
    echo "Waiting for runtime/cosi.${path}.runtime.csv to be created..."
    sleep 5
done

# Monitor and process new sim_ids
monitor_new_sim_ids

echo "Processed all nsl and ihh12 ${path}. Exiting."
