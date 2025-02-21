#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=8000

# Read inputs from JSON file using Python
config_file="config.json"
selected_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selected_simulation_number"])')

# Debugging output
echo "Selected Simulation Number: $selected_simulation_number"

# Create the one_pop_stats directory if it doesn't exist
mkdir -p one_pop_stats

# Function to run selscan commands for a given TPED file
run_selscan_ihs() {
    local tped_file=$1
    local base_name=$(basename $tped_file .tped)
    
    start_time=$(date +%s)
    selscan --ihs --ihs-detail --tped $tped_file --out one_pop_stats/$base_name.ihs --threads 8
    end_time=$(date +%s)
    runtime=$((end_time - start_time))
    echo "ihs runtime for $base_name: $runtime seconds" >> one_pop_stats/runtime.txt
}

# Monitor the sel directory for new TPED files and run selscan commands on them
processed_files=()
while true; do
    for ((sim_id=0; sim_id<=selected_simulation_number; sim_id++)); do
        tped_file="sel/sel.hap.${sim_id}_0_1.tped"
        if [[ ! " ${processed_files[@]} " =~ " ${tped_file} " ]]; then
            if [[ -f "$tped_file" ]]; then
                run_selscan_ihs "$tped_file"
                processed_files+=("$tped_file")
            fi
        fi
    done
    if [[ ${#processed_files[@]} -ge $((selected_simulation_number + 1)) ]]; then
        echo "Processed all required TPED files. Exiting."
        break
    fi
    sleep 10
done

echo "IHS statistics for selected simulations have been calculated and saved in the one_pop_stats directory."
