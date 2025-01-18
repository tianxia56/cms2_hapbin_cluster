args <- commandArgs(trailingOnly = TRUE)
sim_id <- as.integer(args[1])

input_file <- paste0("one_pop_stats/sel.", sim_id, "_0_1.ihs.out")
output_file <- paste0("norm/temp.ihs.", sim_id, ".tsv")

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

colnames(data) <- c("pos", "daf", "ihs", "delihh")

# Extract relevant columns
data <- data[, c("pos", "daf", "ihs")]

# Convert daf to numeric and check for NAs
data$daf <- as.numeric(as.character(data$daf))
if (any(is.na(data$daf))) {
  stop("NA values found in daf column after conversion to numeric.")
}

# Read the normalization file
norm_data <- tryCatch({
  read.csv("bin/ihs_bin.csv", header = TRUE)
}, error = function(e) {
  cat("Error reading normalization file:", e$message, "\n")
  NULL
})

if (is.null(norm_data)) {
  stop("Failed to read normalization file.")
}

# Convert bin files to numeric
norm_data$bin <- as.numeric(as.character(norm_data$bin))
norm_data$mean <- as.numeric(as.character(norm_data$mean))
norm_data$std <- as.numeric(as.character(norm_data$std))

# Function to find the closest bin
find_closest_bin <- function(daf, norm_data) {
  idx <- which.min(abs(norm_data$bin - daf))
  return(norm_data[idx, ])
}

# Normalize ihs
data$norm_ihs <- apply(data, 1, function(row) {
  daf_value <- as.numeric(row["daf"])
  bin_info <- find_closest_bin(daf_value, norm_data)
  mean <- bin_info$mean
  std <- bin_info$std
  if (is.na(mean) || is.na(std) || std == 0) {
    return(NA)
  }
  norm_ihs <- (as.numeric(row["ihs"]) - mean) / std
  return(round(norm_ihs, 4))
})

# Save the output
write.table(data, file = output_file, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)

cat("Finished processing simulation ID:", sim_id, "\n")
