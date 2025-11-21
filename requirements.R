#==============================================================================#
#==================== Project Dependency Installation Script ==================#
#==============================================================================#

# Required packages list
required_packages <- c(
  # Data processing
  "dplyr",      # Data manipulation
  "data.table", # Efficient data read/write
  "tidyr",      # Data tidying
  "purrr",      # Functional programming
  "testthat",
  # Missing value imputation
  "missForest"
)

# Check and install missing packages
check_and_install <- function(packages) {
  # Find packages not installed
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  
  # Install missing packages
  if(length(new_packages)) {
    message("Installing missing packages: ", paste(new_packages, collapse = ", "))
    install.packages(new_packages, dependencies = TRUE)
  } else {
    message("All required packages are already installed.")
  }
}

# Load packages
load_packages <- function(packages) {
  suppressPackageStartupMessages({
    for(package in packages) {
      if(!require(package, character.only = TRUE, quietly = TRUE)) {
        stop("Package loading failed: ", package)
      }
    }
  })
  message("All packages loaded successfully!")
}

# Main process
message("=== Checking Project Dependencies ===")

# Install missing packages
check_and_install(required_packages)

# Load packages
load_packages(required_packages)

# Verify versions
message("\n=== Package Version Information ===")
for(pkg in required_packages) {
  if(pkg %in% installed.packages()[,"Package"]) {
    version <- packageVersion(pkg)
    message(sprintf("- %s: %s", pkg, version))
  }
}

message("\n=== Environment Preparation Completed ===")
