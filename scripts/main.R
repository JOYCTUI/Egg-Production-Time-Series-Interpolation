#==============================================================================#
#==================== MissForest Missing Value Imputation Main Program ========#
#==============================================================================#
# Author: Juntu Lan
# Creation Date: 2025.11.15
#==============================================================================#

# Load configuration and functions
source("config/config.R")
source("scripts/functions.R")

#==============================================================================#
#=============================== Main Process =================================#
#==============================================================================#

message("===== Starting Missing Value Imputation Process =====")

# Create output directories
dir.create(config$output_filled_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(config$output_metrics_dir, showWarnings = FALSE, recursive = TRUE)

# Find seed directories
seed_dirs <- list.dirs(config$na_data_parent_dir, full.names = FALSE, recursive = FALSE)
seed_dirs <- seed_dirs[grepl("^seed_\\d+$", seed_dirs)]

if (length(seed_dirs) == 0)
  stop(sprintf("No seed directories found: %s", config$na_data_parent_dir))

# Read original data
message("Reading original data...")
true_data <- fread(config$true_data_file)

# Perform imputation and evaluation
metrics_summary <- map_dfr(seed_dirs, function(seed_dir) {
  
  message(sprintf("\n===== Processing Seed: %s =====", seed_dir))
  
  # Create seed-specific output directories
  dir.create(file.path(config$output_filled_dir, seed_dir), recursive = TRUE)
  dir.create(file.path(config$output_metrics_dir, seed_dir), recursive = TRUE)
  
  map_dfr(config$na_rates, function(rate) {
    tryCatch({
      
      message(sprintf("-- Missing Rate: %.2f --", rate))
      
      # File path settings
      input_file <- file.path(config$na_data_parent_dir, seed_dir,
                              sprintf("na_data_%.2f.csv", rate))
      output_file <- file.path(config$output_filled_dir, seed_dir,
                               sprintf("filled_data_%.2f.csv", rate))
      metrics_file <- file.path(config$output_metrics_dir, seed_dir,
                                sprintf("metrics_%.2f.csv", rate))
      
      if (!file.exists(input_file)) {
        warning(sprintf("File does not exist: %s", input_file))
        return(NULL)
      }
      
      # Read data with missing values
      na_data <- fread(input_file)
      
      # Perform MissForest imputation
      message("Starting imputation...")
      start_time <- Sys.time()
      filled_data <- rf_impute(na_data, config$missforest_params)
      duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      
      # Save imputation results
      fwrite(filled_data, output_file)
      message(sprintf("Imputation completed, time taken: %.2f seconds", duration))
      
      # Calculate evaluation metrics
      message("Calculating evaluation metrics...")
      num_cols <- 3:ncol(true_data)
      na_mask <- is.na(as.matrix(na_data[, ..num_cols]))
      
      metrics <- calculate_metrics(
        as.matrix(true_data[, ..num_cols]),
        as.matrix(filled_data[, ..num_cols]),
        na_mask
      )
      
      # Save metrics
      fwrite(as.data.table(metrics), metrics_file)
      
      # Return summary results
      return(data.table(
        Seed = seed_dir,
        MissingRate = rate,
        ImputationTime = duration,
        RMSE = metrics$RMSE,
        MSE = metrics$MSE,
        MAE = metrics$MAE,
        R2 = metrics$R2
      ))
      
    }, error = function(e) {
      message(sprintf("Error [Seed: %s, Rate: %.2f]: %s",
                      seed_dir, rate, e$message))
      return(NULL)
    })
  })
})

#==============================================================================#
#=========================== Results Statistics and Analysis ==================#
#==============================================================================#

if (nrow(metrics_summary) > 0) {
  
  # Save detailed metrics summary
  summary_file <- file.path(config$output_metrics_dir, "summary_metrics.csv")
  fwrite(metrics_summary, summary_file)
  message(sprintf("Detailed metrics saved: %s", summary_file))
  
  # Generate statistical summary
  stats_summary <- metrics_summary %>%
    group_by(MissingRate) %>%
    summarise(
      n = n(),
      Time_mean = mean(ImputationTime, na.rm = TRUE),
      across(
        c(RMSE, MSE, MAE, R2),
        list(mean = ~mean(., na.rm = TRUE), sd = ~sd(., na.rm = TRUE)),
        .names = "{.col}_{.fn}"
      ),
      .groups = "drop"
    ) %>%
    mutate(
      RMSE_se = RMSE_sd / sqrt(n),
      MSE_se = MSE_sd / sqrt(n),
      MAE_se = MAE_sd / sqrt(n),
      R2_se = R2_sd / sqrt(n)
    )
  
  # Format output
  formatted_stats <- data.frame(
    MissingRate = stats_summary$MissingRate,
    Samples = stats_summary$n,
    MeanTimeSec = sprintf("%.3f", stats_summary$Time_mean),
    RMSE = sprintf("%.3f ± %.3f", stats_summary$RMSE_mean, stats_summary$RMSE_se),
    MSE  = sprintf("%.3f ± %.3f", stats_summary$MSE_mean, stats_summary$MSE_se),
    MAE  = sprintf("%.3f ± %.3f", stats_summary$MAE_mean, stats_summary$MAE_se),
    R2   = sprintf("%.3f ± %.3f", stats_summary$R2_mean, stats_summary$R2_se),
    check.names = FALSE
  )
  
  # Save statistical summary
  stats_file <- file.path(config$output_metrics_dir, "statistical_summary.csv")
  fwrite(formatted_stats, stats_file)
  
  # Print results
  message("\n===== Statistical Summary =====")
  print(formatted_stats)
  message(sprintf("Statistical summary saved: %s", stats_file))
  
} else {
  message("Warning: No valid evaluation results, please check data files or logs.")
}

message("\n✅ MissForest missing value imputation process completed!")
