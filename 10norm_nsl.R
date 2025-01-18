args <- commandArgs(trailingOnly = TRUE)
sim_id <- as.integer(args[1])

input_file <- paste0("one_pop_stats/sel.", sim_id, ".nsl.out")
output_file <- paste0("norm/temp.nsl.", sim_id, ".tsv")

# Read the input file
data <- tryCatch({
  read.table(input_file, header = FALSE)
}, error = function(e) {
  cat("Error reading input file:", e$message, "\n")
  NULL
})

if (is.null(data)) {
  stop("Failed to read input file.")
}

colnames(data) <- c("locus", "pos", "daf", "sl1", "sl0", "nsl")

# Extract relevant columns
data <- data[, c("pos", "daf", "nsl")]

# Read the normalization file
norm_data <- tryCatch({
  read.csv("bin/nsl_bin.csv", header = TRUE)
}, error = function(e) {
  cat("Error reading normalization file:", e$message, "\n")
  NULL
})

if (is.null(norm_data)) {
  stop("Failed to read normalization file.")
}

# Function to find the closest bin
find_closest_bin <- function(daf, norm_data) {
  idx <- which.min(abs(norm_data$bin - daf))
  return(norm_data[idx, ])
}

# Normalize nsl
data$norm_nsl <- apply(data, 1, function(row) {
  bin_info <- find_closest_bin(row["daf"], norm_data)
  mean <- bin_info$mean
  std <- bin_info$std
  if (is.na(mean) || is.na(std) || std == 0) {
    return(NA)
  }
  norm_nsl <- (row["nsl"] - mean) / std
  return(round(norm_nsl, 4))
})

# Print final data to debug
#cat("Final data:\n")
#print(head(data))

# Save the output
write.table(data, file = output_file, sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)

cat("Finished processing simulation ID:", sim_id, "\n")
