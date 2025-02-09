#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=8000

# Extract population IDs and pop1 from the config file
config_file="00config.json"
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
pop_ids=($(grep "^pop_define" $demographic_model | awk '{print $2}'))
neutral_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["neutral_simulation_number"])')
pop1=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selective_sweep"].split()[3])')
path="neut"

echo "Starting hapbin ihs for neut..."

# Function to run ihs for each simulation
run_ihsbin() {
    local sim_id=$1
    local pop1=$2
    local path=$3

    hap="hapbin/${path}.${sim_id}_0_${pop1}.hap"
    map_file="hapbin/${path}.${sim_id}_0_${pop1}.map"
    output_file="hapbin/${path}.hap.${sim_id}.ihs.out"
    command="/home/tx56/hapbin/build/ihsbin --hap $hap --map $map_file --out $output_file"
    
    start_time=$(date +%s)
    echo "Running ihs ${path} for ${path}.hap.${sim_id}"
    $command
    end_time=$(date +%s)
    runtime=$((end_time - start_time))
    echo "sim_id,$sim_id,ihs_${path}_runtime,$runtime,seconds" >> "runtime/ihs.${path}.runtime.csv"
}

# Function to add pos and daf columns to ihs.out files
add_pos_and_daf() {
    local sim_id=$1
    local pop1=$2
    local path=$3

    python3 07add_ihs_daf.py "$sim_id" "$pop1" "$path"
}

# Monitor and process simulations for path "neut"
monitor_and_process_simulations() {
    processed_neut=0
    processed_ids=()
    last_mod_time=$(date +%s)

    # Wait for the CSV file to be created
    while [ ! -f runtime/xpehh.neut.map.runtime.csv ]; do
        echo "Waiting for runtime/xpehh.neut.map.runtime.csv to be created..."
        sleep 2
    done

    prev_row_count_neut=0
    
    while true; do
        current_row_count_neut=$(wc -l < runtime/xpehh.neut.map.runtime.csv)
        current_time=$(date +%s)
        
        if [ $processed_neut -eq $((neutral_simulation_number + 1)) ]; then
            echo "Processed all required TPED files for neut. Exiting."
            break  # Exit the while loop
        fi
        
        new_sim_ids_neut=$(tail -n +1 runtime/xpehh.neut.map.runtime.csv | awk -F, 'NR > prev_row_count_neut {print $2}' prev_row_count_neut=$prev_row_count_neut)
        
        for sim_id in $new_sim_ids_neut; do
            if [[ ! " ${processed_ids[@]} " =~ " ${sim_id} " ]]; then
                run_ihsbin "$sim_id" "$pop1" "neut"
                add_pos_and_daf "$sim_id" "$pop1" "neut"
                processed_ids+=("$sim_id")
                processed_neut=$((processed_neut + 1))
                last_mod_time=$(date +%s)  # Update last modification time
            fi
        done
        
        # Check if the file has not been modified for 30 minutes (1800 seconds)
        if (( current_time - last_mod_time > 1800 )); then
            echo "No new lines added to runtime/xpehh.neut.map.runtime.csv for 30 minutes. Stopping script."
            break
        fi
        
        prev_row_count_neut=$current_row_count_neut
        
        sleep 2  # Wait before checking for new rows again
    done
}

# Monitor and process simulations for path "neut"
monitor_and_process_simulations

echo "Hapbin processing ihs for neut has been completed and saved in the one_pop_stats directory."
