import sys
import os
import json

def extract_and_clean_columns(input_file, output_file_map, output_file_hap):
    with open(input_file, 'r') as file, open(output_file_map, 'w') as map_file, open(output_file_hap, 'w') as hap_file:
        for line in file:
            columns = line.split()
            if len(columns) < 5:
                continue
            map_file.write(' '.join(columns[:4]) + '\n')  # Extract the first four columns with whitespace separator
            cleaned_columns = [col.strip() for col in columns[4:]]  # Clean columns
            hap_file.write(' '.join(cleaned_columns) + '\n')  # Write cleaned columns with whitespace separator

def create_map_file(original_map_file):
    temp_file = original_map_file + ".tmp"
    with open(original_map_file, 'r') as map_file, open(temp_file, 'w') as new_file:
        for line in map_file:
            columns = line.split()
            # Ensure the columns are correctly formatted for ASCII and convert scientific notation to numeric
            formatted_columns = [col.encode('ascii', 'ignore').decode('ascii') for col in columns]
            formatted_columns = [f"{float(col):.6f}" if 'e' in col else col for col in formatted_columns]
            # Join columns with a single space and remove any non-printable characters
            cleaned_line = ' '.join(formatted_columns).strip()
            new_file.write(cleaned_line + '\n')
    os.replace(temp_file, original_map_file)
    print(f"Map file created: {original_map_file}")

def main(sim_id, pop_id, pop1, config_file, max_pop_id):
    input_file = f"sel/sel.hap.{sim_id}_0_{pop_id}.tped"
    
    if not os.path.exists(input_file):
        print(f"Skipping {sim_id} as {input_file} does not exist.")
        return

    os.makedirs("hapbin", exist_ok=True)
    output_file_hap = f"hapbin/{sim_id}_0_{pop_id}.hap"
    output_file_map = f"hapbin/{sim_id}_0_{pop1}.map"
    extract_and_clean_columns(input_file, output_file_map, output_file_hap)
    print(f"Extracted columns saved to {output_file_map} and {output_file_hap}")
    create_map_file(output_file_map)

if __name__ == "__main__":
    if len(sys.argv) != 6:
        print("Usage: python extract_columns.py <sim_id> <pop_id> <pop1> <config_file> <max_pop_id>")
        sys.exit(1)
    
    sim_id = sys.argv[1]
    pop_id = sys.argv[2]
    pop1 = sys.argv[3]
    config_file = sys.argv[4]
    max_pop_id = sys.argv[5]
    main(sim_id, pop_id, pop1, config_file, max_pop_id)
