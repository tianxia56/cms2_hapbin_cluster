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
simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["neutral_simulation_number"])')
pop1=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selective_sweep"].split()[3])')
max_pop_id=$(echo "${pop_ids[@]}" | tr ' ' '\n' | sort -nr | head -n1)
path="neut"

echo "Starting hapbin processing script..."

# Function to run hapbin processing for each simulation
generate_map_and_haps() {
    local sim_id=$1
    local path=$2
    
    echo "Processing simulation ID: $sim_id"
    
    start_time=$(date +%s)
    for pop_id in "${pop_ids[@]}"; do
        python3 06hapbin.map.path.py "$sim_id" "$pop_id" "$pop1" "$config_file" "$max_pop_id" "$path"
    done
    end_time=$(date +%s)
    runtime=$((end_time - start_time))
    echo "sim_id,$sim_id,${path}_runtime_map_and_hap,xpehh_1vs$pop2,$runtime,seconds" >> "runtime/xpehh.${path}.map.runtime.csv"
}

# Function to run xpehhbin for each simulation
run_xpehhbin() {
    local sim_id=$1
    local pop1=$2
    local max_pop_id=$3

    for pop2 in $(seq 1 $max_pop_id); do
        if [[ $pop2 -ne $pop1 ]]; then
            hapA="hapbin/${path}.${sim_id}_0_${pop1}.hap"
            hapB="hapbin/${path}.${sim_id}_0_${pop2}.hap"
            map_file="hapbin/${path}.${sim_id}_0_${pop1}.map"
            output_file="hapbin/${path}.${sim_id}_${pop1}_vs_${pop2}.xpehh.out"
            command="/home/tx56/hapbin/build/xpehhbin --hapA $hapA --hapB $hapB --map $map_file --out $output_file"
            
            start_time=$(date +%s)
            echo "Running xpehhbin for $pop1 vs $pop2"
            $command
            end_time=$(date +%s)
            runtime=$((end_time - start_time))
            echo "sim_id,$sim_id,${path}_runtime,xpehh_1vs$pop2,$runtime,seconds" >> "runtime/xpehh.${path}.runtime.csv"
        fi
    done
}

# Function to add pos and daf columns to xpehh.out files
add_pos_and_daf() {
    local sim_id=$1
    local pop1=$2
    local max_pop_id=$3
    local path=$4

    python3 06add_xpehh_daf.py "$sim_id" "$pop1" "$max_pop_id" "$path"
}

# Monitor and process simulations
processed_files=()
while true; do
    # Check if the CSV file exists
    if [[ -f runtime/nsl.${path}.runtime.csv ]]; then
        # Process each unique sim_id from the CSV file
        new_sim_ids=$(awk -F, '{print $2}' runtime/nsl.${path}.runtime.csv)
        for sim_id in $new_sim_ids; do
            if [[ ! " ${processed_files[@]} " =~ " ${sim_id} " ]]; then
                generate_map_and_haps "$sim_id" "$path"
                run_xpehhbin "$sim_id" "$pop1" "$max_pop_id"
                add_pos_and_daf "$sim_id" "$pop1" "$max_pop_id" "$path"
                processed_files+=("${sim_id}")
            fi
        done

        # Check if all simulations have been processed
        if [[ ${#processed_files[@]} -eq $((simulation_number + 1)) ]]; then
            echo "Processed all required TPED files. Exiting."
            break  # Exit the while loop
        fi
    else
        echo "Waiting for runtime/nsl.sel.runtime.csv to be created..."
    fi

    sleep 10  # Wait before checking for new files
done

echo "Hapbin processing for selected simulations has been completed and saved in the hapbin directory."
