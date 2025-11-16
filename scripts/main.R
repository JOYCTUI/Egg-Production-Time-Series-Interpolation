#==============================================================================#
#==================== MissForest缺失值插补主程序 ==============================#
#==============================================================================#
# 作者: Juntu Lan
# 创建日期: 2025.11.15
#==============================================================================#

# 加载配置和函数
source("config/config.R")
source("scripts/functions.R")

#==============================================================================#
#=============================== 主流程 =======================================#
#==============================================================================#

message("===== 开始缺失值插补流程 =====")

# 创建输出目录
dir.create(config$output_filled_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(config$output_metrics_dir, showWarnings = FALSE, recursive = TRUE)

# 查找种子目录
seed_dirs <- list.dirs(config$na_data_parent_dir, full.names = FALSE, recursive = FALSE)
seed_dirs <- seed_dirs[grepl("^seed_\\d+$", seed_dirs)]

if (length(seed_dirs) == 0)
  stop(sprintf("未找到种子目录: %s", config$na_data_parent_dir))

# 读取原始数据
message("正在读取原始数据...")
true_data <- fread(config$true_data_file)

# 执行插补和评估
metrics_summary <- map_dfr(seed_dirs, function(seed_dir) {
  
  message(sprintf("\n===== 处理种子: %s =====", seed_dir))
  
  # 创建种子特定的输出目录
  dir.create(file.path(config$output_filled_dir, seed_dir), recursive = TRUE)
  dir.create(file.path(config$output_metrics_dir, seed_dir), recursive = TRUE)
  
  map_dfr(config$na_rates, function(rate) {
    tryCatch({
      
      message(sprintf("-- 缺失率: %.2f --", rate))
      
      # 文件路径设置
      input_file <- file.path(config$na_data_parent_dir, seed_dir,
                              sprintf("na_data_%.2f.csv", rate))
      output_file <- file.path(config$output_filled_dir, seed_dir,
                               sprintf("filled_data_%.2f.csv", rate))
      metrics_file <- file.path(config$output_metrics_dir, seed_dir,
                                sprintf("metrics_%.2f.csv", rate))
      
      if (!file.exists(input_file)) {
        warning(sprintf("文件不存在: %s", input_file))
        return(NULL)
      }
      
      # 读取含缺失值的数据
      na_data <- fread(input_file)
      
      # 执行MissForest插补
      message("开始插补...")
      start_time <- Sys.time()
      filled_data <- rf_impute(na_data, config$missforest_params)
      duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
      
      # 保存插补结果
      fwrite(filled_data, output_file)
      message(sprintf("插补完成，耗时: %.2f秒", duration))
      
      # 计算评估指标
      message("计算评估指标...")
      num_cols <- 3:ncol(true_data)
      na_mask <- is.na(as.matrix(na_data[, ..num_cols]))
      
      metrics <- calculate_metrics(
        as.matrix(true_data[, ..num_cols]),
        as.matrix(filled_data[, ..num_cols]),
        na_mask
      )
      
      # 保存指标
      fwrite(as.data.table(metrics), metrics_file)
      
      # 返回汇总结果
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
      message(sprintf("错误 [Seed: %s, Rate: %.2f]: %s",
                      seed_dir, rate, e$message))
      return(NULL)
    })
  })
})

#==============================================================================#
#=========================== 结果统计与分析 ===================================#
#==============================================================================#

if (nrow(metrics_summary) > 0) {
  
  # 保存详细指标汇总
  summary_file <- file.path(config$output_metrics_dir, "summary_metrics.csv")
  fwrite(metrics_summary, summary_file)
  message(sprintf("详细指标已保存: %s", summary_file))
  
  # 生成统计摘要
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
  
  # 格式化输出
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
  
  # 保存统计摘要
  stats_file <- file.path(config$output_metrics_dir, "statistical_summary.csv")
  fwrite(formatted_stats, stats_file)
  
  # 打印结果
  message("\n===== 统计摘要 =====")
  print(formatted_stats)
  message(sprintf("统计摘要已保存: %s", stats_file))
  
} else {
  message("警告：没有有效的评估结果，请检查数据文件或日志。")
}

message("\n✅ MissForest缺失值插补流程全部完成!")