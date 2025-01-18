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
simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selected_simulation_number"])')
pop1=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selective_sweep"].split()[3])')

echo "Starting FST and ΔDAF computation script..."
mkdir -p two_pop_stats
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

# Monitor and process simulations
processed_files=()
for ((sim_id=0; sim_id<=simulation_number; sim_id++)); do
    all_files_exist=true
    for pop_id in "${pop_ids[@]}"; do
        tped_file="sel/sel.hap.${sim_id}_0_${pop_id}.tped"
        if [[ ! -f "$tped_file" ]]; then
            all_files_exist=false
            break
        fi
    done
    
    if $all_files_exist; then
        if [[ ! " ${processed_files[@]} " =~ " ${sim_id} " ]]; then
            run_fst_deldaf "$sim_id" "$pop1"
            processed_files+=("${sim_id}")
        fi
    fi
done

echo "Processed all required TPED files. Exiting."

echo "FST and ΔDAF statistics for selected simulations have been calculated and saved in the two_pop_stats directory."
