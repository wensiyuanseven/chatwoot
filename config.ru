# This file is used by Rack-based servers to start the application.
# 基于 Rack 的服务器使用该文件来启动应用程序。

# 初始化 Rails 应用环境。
require_relative 'config/environment'

# 启动 Rails 应用实例，并将其绑定到 Rack 接口。
run Rails.application
