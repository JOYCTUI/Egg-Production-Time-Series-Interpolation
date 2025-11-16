#==============================================================================#
#==================== 项目配置文件 ============================================#
#==============================================================================#

# 定位脚本所在目录
root_dir <- tryCatch(
  dirname(normalizePath(sys.frame(1)$ofile)),
  error = function(e) getwd()
)

# 主配置列表
config <- list(
  
  # ==================== 目录设置 ==================== #
  
  # 项目根目录
  root_dir = root_dir,
  
  # 数据目录
  data_dir = file.path(root_dir, "data"),
  source_data_dir = file.path(root_dir, "data", "source_data"),
  na_data_dir = file.path(root_dir, "data", "na_data"),
  
  # 输出目录
  output_dir = file.path(root_dir, "outputs"),
  filled_data_dir = file.path(root_dir, "outputs", "filled_data_rf"),
  metrics_dir = file.path(root_dir, "outputs", "evaluation_metrics_rf"),
  
  # ==================== 文件路径 ==================== #
  
  # 数据文件
  true_data_file = file.path(root_dir, "data", "source_data", "clean_data.csv"),
  na_data_parent_dir = file.path(root_dir, "data", "na_data"),
  
  # ==================== 实验参数 ==================== #
  
  # 缺失率设置
  na_rates = c(0.05, 0.10, 0.15, 0.20),
  
  # 随机种子数量（用于生成测试数据）
  n_seeds = 5,
  
  # ==================== 参数设置 ==================== #
  
  missforest_params = list(
    ntree = 200,            # 每棵树的数量
    maxiter = 10,           # 最大迭代次数
    parallelize = "forests" # 并行方式
  ),
  
  # ==================== 其他设置 ==================== #
  
  # 随机种子
  random_seed = 123,
  
  # 是否显示详细日志
  verbose = TRUE
)

# ==================== 目录创建 ==================== #

# 确保必要的目录存在
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
        message("创建目录: ", dir)
      }
    }
  }
}

# 初始化目录
create_directories()

# 设置工作目录
setwd(config$root_dir)

message("配置文件加载完成")