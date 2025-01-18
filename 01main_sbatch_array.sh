#!/bin/bash
#SBATCH --partition=ycga
#SBATCH --time=2-00:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4000

# Create output directory if it doesn't exist
mkdir -p output

# Function to wait for jobs to complete
wait_for_jobs() {
    job_ids=("$@")
    for job_id in "${job_ids[@]}"; do
        while : ; do
            job_status=$(squeue --job "$job_id" --noheader --format "%T" 2>/dev/null)
            if [[ -z "$job_status" || "$job_status" == "COMPLETED" || "$job_status" == "FAILED" || "$job_status" == "CANCELLED" ]]; then
                break
            fi
            sleep 10
        done
    done
}

# Record the start time of the entire process
start_time_total=$(date +%s)

job_ids=()
###########################################################################################
##################################################### Submit tasks for selected simulations
job_ids+=($(sbatch --parsable 02cs_1_sel.sh))
job_ids+=($(sbatch --parsable 02cs_2_sel.sh))
job_ids+=($(sbatch --parsable 02cs_3_sel.sh))
job_ids+=($(sbatch --parsable 02cs_4_sel.sh))
job_ids+=($(sbatch --parsable 02cs_5_sel.sh))

################################################### Submit tasks for neutral simulations
job_ids+=($(sbatch --parsable 03cs_even_neut.sh))
job_ids+=($(sbatch --parsable 03cs_odd_neut.sh))

########################################################################################
################################################### Submit nsl and ihh12 sel and neut
job_ids+=($(sbatch --parsable 04nsl_ihh12_sel.sh))
job_ids+=($(sbatch --parsable 04nsl_ihh12_neut.sh))

#######################################################################################
################################################### Submit isafe
job_ids+=($(sbatch --parsable 05isafe.sh))

#######################################################################################
################################################## Submit hapbin xpehh sel and neut
job_ids+=($(sbatch --parsable 06xpehh_sel.sh))
job_ids+=($(sbatch --parsable 06xpehh_neut.sh))

######################################################################################
################################################# Submit hapbin ihs sel and neut
job_ids+=($(sbatch --parsable 07ihs_sel.sh))
job_ids+=($(sbatch --parsable 07ihs_neut.sh))

######################################################################################
############################################## Wait for all initial jobs to complete
wait_for_jobs "${job_ids[@]}"

######################################################################################
############################################## Check for missing sims

#wait_for_jobs "${debug_ids[@]}"
######################################################################################
################# Submit task to normalize
bin_job_id=$(sbatch --parsable 08make_bins.sh)

# Wait for make_bin_fil
wait_for_jobs "$bin_job_id"

######################################################################################
########################################################### Submit fst deldaf.sh task
fst_job_id=$(sbatch --parsable --export=ALL,pop_ids="${pop_ids[*]}" 09fst_deldaf.sh)

######################################################################################
########################################################## Submit normalization jobs
norm_jobs=()
norm_jobs+=($(sbatch --parsable 10norm_ihs.sh))
norm_jobs+=($(sbatch --parsable 10norm_nsl.sh))
norm_jobs+=($(sbatch --parsable 10norm_ihh12.sh))
norm_jobs+=($(sbatch --parsable 10norm_delihh.sh))
norm_jobs+=($(sbatch --parsable 10norm_xpehhbin.sh))

#####################################################################################
######################################### Wait for all normalization jobs to complete
wait_for_jobs "${norm_jobs[@]}"

#####################################################################################
############################################################## Submit final_output.sh
final_output_job_id=$(sbatch --parsable 11output.sh)

####################################################################################
# Record the total runtime
# Define variables
config_file="00config.json"
simulation_serial_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["simulation_serial_number"])')
demographic_model=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["demographic_model"])')
selected_simulation_number=$(python3 -c 'import json; print(json.load(open("'"$config_file"'"))["selected_simulation_number"])')
end_time_total=$(date +%s)
total_runtime=$((end_time_total - start_time_total))
total_runtime_formatted=$(printf '%02d:%02d:%02d' $((total_runtime/3600)) $((total_runtime%3600/60)) $((total_runtime%60)))
echo "Total runtime: $demographic_model $((selected_simulation_number+1)) sims, serial number $simulation_serial_number $total_runtime_formatted, Date: $(date)" >> output/totalruntime.txt
