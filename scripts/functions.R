#==============================================================================#
#==================== 函数定义文件 ============================================#
#==============================================================================#
#' 计算插补评估指标
#'
#' @param true 真实值矩阵
#' @param pred 预测值矩阵  
#' @param na_mask 缺失值位置掩码
#' @return 包含RMSE, MSE, MAE, R2的列表
#' @export
calculate_metrics <- function(true, pred, na_mask) {
  true_values <- true[na_mask]
  pred_values <- pred[na_mask]
  
  if (length(true_values) == 0) {
    return(list(RMSE = NA, MSE = NA, MAE = NA, R2 = NA))
  }
  
  # 移除NA值
  valid_indices <- !is.na(true_values) & !is.na(pred_values)
  true_values <- true_values[valid_indices]
  pred_values <- pred_values[valid_indices]
  
  if (length(true_values) == 0) {
    return(list(RMSE = NA, MSE = NA, MAE = NA, R2 = NA))
  }
  
  # 计算误差指标
  errors <- true_values - pred_values
  mse <- mean(errors^2)
  rmse <- sqrt(mse)
  mae <- mean(abs(errors))
  
  # 计算R²
  ss_total <- sum((true_values - mean(true_values))^2)
  ss_residual <- sum(errors^2)
  r2 <- ifelse(ss_total > 0, 1 - (ss_residual / ss_total), NA)
  
  return(list(RMSE = rmse, MSE = mse, MAE = mae, R2 = r2))
}

#' 使用MissForest进行缺失值插补
#'
#' @param na_data 包含缺失值的数据框
#' @param mf_params MissForest参数列表
#' @return 插补完成的数据框
#' @export
rf_impute <- function(na_data, mf_params) {
  # 验证数据格式
  if (!all(c("wingId", "batch") %in% colnames(na_data))) {
    stop("数据必须包含 wingId 和 batch 列")
  }
  
  # 备份ID列
  wingId_backup <- na_data$wingId
  
  # 准备插补数据
  df_for_impute <- na_data %>%
    mutate(batch = as.factor(batch)) %>%
    select(-wingId)
  
  message("执行MissForest插补...")
  # 执行插补
  set.seed(123)  # 确保可重复性
  imputed_result <- missForest(
    df_for_impute,
    ntree = mf_params$ntree,
    maxiter = mf_params$maxiter,
    parallelize = mf_params$parallelize,
    verbose = TRUE
  )
  
  # 恢复数据格式
  imputed_data <- imputed_result$ximp %>%
    mutate(wingId = wingId_backup) %>%
    select(wingId, everything())
  
  # 确保数值列非负
  week_cols <- grep("^\\d+$", names(imputed_data), value = TRUE)
  imputed_data <- imputed_data %>%
    mutate(across(all_of(week_cols), ~ pmax(., 0)))
  
  message("MissForest插补完成")
  return(imputed_data)
}