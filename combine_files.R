library(dplyr)
library(readr)
library(stringr)

input_folder <- "data/to_combine"
output_name  <- "Test_Series_Aus"

# Read all CSVs
files     <- list.files(input_folder, pattern = "\\.csv$", full.names = TRUE)
data_list <- lapply(files, read_csv)
names(data_list) <- basename(files)

# Add Timeline and Opponent columns
data_list <- lapply(names(data_list), function(fname) {
  data_list[[fname]] %>%
    mutate(
      Timeline = str_remove(fname, "\\.csv$"),
      Opponent = str_replace(fname, ".*vs (.+)_\\d{8}\\.csv", "\\1")
    ) %>%
    select(Timeline, Opponent, everything())
})

# Check columns against first file
reference_cols <- colnames(data_list[[1]])
mismatches <- c()

for (fname in names(data_list)) {
  cols <- colnames(data_list[[fname]])
  if (!identical(sort(cols), sort(reference_cols))) {
    missing <- setdiff(reference_cols, cols)
    extra   <- setdiff(cols, reference_cols)
    msg <- paste0("  - ", fname)
    if (length(missing) > 0) msg <- paste0(msg, "\n    Missing: ", paste(missing, collapse = ", "))
    if (length(extra)   > 0) msg <- paste0(msg, "\n    Extra:   ", paste(extra,   collapse = ", "))
    mismatches <- c(mismatches, msg)
  }
}

# Report mismatches or combine
if (length(mismatches) > 0) {
  stop("Column mismatch detected. Fix these files before combining:\n",
       paste(mismatches, collapse = "\n"))
} else {
  combined    <- bind_rows(data_list)
  output_path <- paste0("data/combined_", output_name, ".csv")
  write_csv(combined, output_path)
  message("Done. ", nrow(combined), " rows written to '", output_path, "'.")
}