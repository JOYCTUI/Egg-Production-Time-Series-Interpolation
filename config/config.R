#==============================================================================#
#==================== Project Configuration File ==============================#
#==============================================================================#

# Locate script directory
root_dir <- getwd()

# Main configuration list
config <- list(
  
  # ==================== Directory Settings ==================== #
  
  # Project root directory
  root_dir = root_dir,
  
  # Data directories
  data_dir        = file.path("data"),
  source_data_dir = file.path("data", "source_data"),
  na_data_dir     = file.path("data", "na_data"),
  
  # Output directories
  output_dir      = file.path("outputs"),
  filled_data_dir = file.path("outputs", "filled_data_rf"),
  metrics_dir     = file.path("outputs", "evaluation_metrics_rf"),
  
  # ==================== File Paths ==================== #
  
  # Data files
  true_data_file     = file.path("data", "source_data", "clean_data.csv"),
  na_data_parent_dir = file.path("data", "na_data"),
  
  # ==================== Experiment Parameters ==================== #
  
  # Missing rate settings
  na_rates = c(0.05, 0.10, 0.15, 0.20),
  
  # Number of random seeds
  n_seeds = 5,
  
  # ==================== Parameter Settings ==================== #
  
  missforest_params = list(
    ntree = 200,            
    maxiter = 10,           
    parallelize = "forests" 
  ),
  
  # ==================== Other Settings ==================== #
  
  random_seed = 123,
  verbose = TRUE
)

# ==================== Directory Creation ==================== #

# Ensure necessary directories exist
create_directories <- function() {
  dirs_to_create <- c(
    config$source_data_dir,
    config$na_data_dir, 
    config$filled_data_dir,
    config$metrics_dir
  )
  
  for (dir in dirs_to_create) {
    if (!dir.exists(dir)) {
      dir.create(dir, recursive = TRUE, showWarnings = FALSE)
      if (config$verbose) {
        message("Created directory: ", dir)
      }
    }
  }
}

# Initialize directories
create_directories()

message("Configuration file loaded successfully")
