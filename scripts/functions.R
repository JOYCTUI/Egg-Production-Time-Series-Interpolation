#==============================================================================#
#==================== Function Definitions File ===============================#
#==============================================================================#

#' Calculate Imputation Evaluation Metrics
#'
#' @param true True value matrix
#' @param pred Predicted value matrix  
#' @param na_mask Missing value position mask
#' @return List containing RMSE, MSE, MAE, R2
#' @export
calculate_metrics <- function(true, pred, na_mask) {
  true_values <- true[na_mask]
  pred_values <- pred[na_mask]
  
  if (length(true_values) == 0) {
    return(list(RMSE = NA, MSE = NA, MAE = NA, R2 = NA))
  }
  
  # Remove NA values
  valid_indices <- !is.na(true_values) & !is.na(pred_values)
  true_values <- true_values[valid_indices]
  pred_values <- pred_values[valid_indices]
  
  if (length(true_values) == 0) {
    return(list(RMSE = NA, MSE = NA, MAE = NA, R2 = NA))
  }
  
  # Calculate error metrics
  errors <- true_values - pred_values
  mse <- mean(errors^2)
  rmse <- sqrt(mse)
  mae <- mean(abs(errors))
  
  # Calculate R²
  ss_total <- sum((true_values - mean(true_values))^2)
  ss_residual <- sum(errors^2)
  r2 <- ifelse(ss_total > 0, 1 - (ss_residual / ss_total), NA)
  
  return(list(RMSE = rmse, MSE = mse, MAE = mae, R2 = r2))
}

#' Perform Missing Value Imputation using MissForest
#'
#' @param na_data Dataframe containing missing values
#' @param mf_params MissForest parameters list
#' @return Completed imputation dataframe
#' @export
rf_impute <- function(na_data, mf_params) {
  # Validate data format
  if (!all(c("wingId", "batch") %in% colnames(na_data))) {
    stop("Data must contain wingId and batch columns")
  }
  
  # Backup ID columns
  wingId_backup <- na_data$wingId
  
  # Prepare data for imputation
  df_for_impute <- na_data %>%
    mutate(batch = as.factor(batch)) %>%
    select(-wingId)
  
  message("Executing MissForest imputation...")
  # Perform imputation
  set.seed(123)  # Ensure reproducibility
  imputed_result <- missForest(
    df_for_impute,
    ntree = mf_params$ntree,
    maxiter = mf_params$maxiter,
    parallelize = mf_params$parallelize,
    verbose = TRUE
  )
  
  # Restore data format
  imputed_data <- imputed_result$ximp %>%
    mutate(wingId = wingId_backup) %>%
    select(wingId, everything())
  
  # Ensure numeric columns are non-negative
  week_cols <- grep("^\\d+$", names(imputed_data), value = TRUE)
  imputed_data <- imputed_data %>%
    mutate(across(all_of(week_cols), ~ pmax(., 0)))
  
  message("MissForest imputation completed")
  return(imputed_data)
}
