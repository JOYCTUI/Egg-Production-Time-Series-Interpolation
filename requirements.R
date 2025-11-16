#==============================================================================#
#==================== 项目依赖包安装脚本 ======================================#
#==============================================================================#

# 所需包列表
required_packages <- c(
  # 数据处理
  "dplyr",      # 数据操作
  "data.table", # 高效数据读写
  "tidyr",      # 数据整理
  "purrr",      # 函数式编程
  "testthat",
  # 缺失值插补
  "missForest"
)

# 检查并安装缺失的包
check_and_install <- function(packages) {
  # 查找未安装的包
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  
  # 安装缺失的包
  if(length(new_packages)) {
    message("正在安装缺失的包: ", paste(new_packages, collapse = ", "))
    install.packages(new_packages, dependencies = TRUE)
  } else {
    message("所有所需包已安装。")
  }
}

# 加载包
load_packages <- function(packages) {
  suppressPackageStartupMessages({
    for(package in packages) {
      if(!require(package, character.only = TRUE, quietly = TRUE)) {
        stop("包加载失败: ", package)
      }
    }
  })
  message("所有包加载成功!")
}

# 主流程
message("=== 检查项目依赖 ===")

# 安装缺失包
check_and_install(required_packages)

# 加载包
load_packages(required_packages)

# 验证版本
message("\n=== 包版本信息 ===")
for(pkg in required_packages) {
  if(pkg %in% installed.packages()[,"Package"]) {
    version <- packageVersion(pkg)
    message(sprintf("- %s: %s", pkg, version))
  }
}

message("\n=== 环境准备完成 ===")