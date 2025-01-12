args <- commandArgs(trailingOnly = TRUE)
sim_id <- as.integer(args[1])
pair_id <- args[2]

input_file <- paste0("hapbin/sel.", sim_id, "_", pair_id, ".xpehh.out")
output_file <- paste0("norm/temp.xpehh.", sim_id, "_", pair_id, ".tsv")

# Read the input file, skipping the header row
data <- tryCatch({
  read.table(input_file, header = TRUE)
}, error = function(e) {
  cat("Error reading input file:", e$message, "\n")
  NULL
})

if (is.null(data)) {
  stop("Failed to read input file.")
}

# Ensure the data has the correct number of columns
if (ncol(data) != 3) {
  stop("Input file does not have 3 columns.")
}

colnames(data) <- c("pos", "daf", "xpehh")

# Convert daf and xpehh to numeric, handling NAs
data$daf <- as.numeric(as.character(data$daf))
data$xpehh <- as.numeric(as.character(data$xpehh))

# Print data to debug
cat("Data after conversion to numeric:\n")
print(head(data))

# Read the normalization file
norm_file <- paste0("norm/norm_xpehh_", pair_id, ".bin")
norm_data <- tryCatch({
  read.table(norm_file, header = TRUE)
}, error = function(e) {
  cat("Error reading normalization file:", e$message, "\n")
  NULL
})

if (is.null(norm_data)) {
  stop("Failed to read normalization file.")
}

# Convert bin to numeric, handling NAs
norm_data$bin <- as.numeric(as.character(norm_data$bin))

# Print norm_data to debug
cat("Normalization data:\n")
print(head(norm_data))

# Function to find the closest bin
find_closest_bin <- function(daf, norm_data) {
  idx <- which.min(abs(norm_data$bin - daf))
  return(norm_data[idx, ])
}

# Normalize xpehh
data$norm_xpehh <- apply(data, 1, function(row) {
  bin_info <- find_closest_bin(as.numeric(row["daf"]), norm_data)
  mean <- bin_info$mean
  std <- bin_info$std
  norm_xpehh <- (as.numeric(row["xpehh"]) - mean) / std
  return(round(norm_xpehh, 4))
})

# Convert norm_xpehh to numeric, handling NAs
data$norm_xpehh <- as.numeric(as.character(data$norm_xpehh))

# Print final data to debug
cat("Final data:\n")
print(head(data))

# Save the output
write.table(data, file = output_file, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
