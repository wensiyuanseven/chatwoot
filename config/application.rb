# frozen_string_literal: true

# Ruby 2.3+ 的优化功能，冻结所有字符串文字，防止在运行时修改，提升性能。
# Rails 应用的核心配置文件之一，定义了应用的初始化逻辑和全局配置
# 引入 boot.rb 文件，boot.rb 主要加载 Bundler 并设置应用的加载路径。
require_relative 'boot'
# 加载 Rails 的所有子模块，比如 ActiveRecord、ActionController、ActiveSupport 等。
# Rails 的语法糖，一次性加载所有 Rails 组件
require 'rails/all'

# 需要 Gemfile 中列出的宝石，包括任何宝石
# 您仅限于：测试、：开发或：生产。
# 加载 Gemfile 中定义的所有依赖项。 Rails.groups 会根据当前运行的环境（如 :test, :development, :production），加载特定的组。
# Rails是常量
Bundler.require(*Rails.groups)
# 加载特定的 APM 代理
# 我们依赖 DOTENV 来加载环境变量
# 我们需要这些环境变量来加载特定的 APM 代理
Dotenv::Rails.load
require 'ddtrace' if ENV.fetch('DD_TRACE_AGENT_URL', false).present?
require 'elastic-apm' if ENV.fetch('ELASTIC_APM_SECRET_TOKEN', false).present?
require 'scout_apm' if ENV.fetch('SCOUT_KEY', false).present?

if ENV.fetch('NEW_RELIC_LICENSE_KEY', false).present?
  require 'newrelic-sidekiq-metrics'
  require 'newrelic_rpm'
end

if ENV.fetch('SENTRY_DSN', false).present?
  require 'sentry-ruby'
  require 'sentry-rails'
  require 'sentry-sidekiq'
end

# 自动缩放
if ENV.fetch('JUDOSCALE_URL', false).present?
  require 'judoscale-rails'
  require 'judoscale-sidekiq'
end

module Chatwoot
  class Application < Rails::Application
    # 初始化最初生成的 Rails 版本的配置默认值。
    config.load_defaults 7.0

    config.eager_load_paths << Rails.root.join('lib')
    config.eager_load_paths << Rails.root.join('enterprise/lib')
    # rubocop：禁用 Rails/FilePath
    config.eager_load_paths += Dir["#{Rails.root}/enterprise/app/**"]
    # rubocop：启用 Rails/FilePath

    # config/environments/* 中的设置优先于此处指定的设置。
    # 应用程序配置可以放入 config/initializers 中的文件中
    # -- 加载后会自动加载该目录中的所有.rb文件
    # 应用程序内的框架和所有精华。
    config.generators.javascripts = false
    config.generators.stylesheets = false

    # 自定义 chatwoot 配置
    config.x = config_for(:app).with_indifferent_access

    # https://stackoverflow.com/questions/72970170/upgrading-to-rails-6-1-6-1-causes-psychdisallowedclass-tried-to-load-unspecif
    # https://discuss.rubyonrails.org/t/cve-2022-32224-possible-rce-escalation-bug-with-serialized-columns-in-active-record/81017
    # 修复我：修复安装配置损坏。我们需要迁移。
    config.active_record.yaml_column_permitted_classes = [ActiveSupport::HashWithIndifferentAccess]
  end

  def self.config
    @config ||= Rails.configuration.x
  end

  def self.redis_ssl_verify_mode
    # 引入此方法是为了修复 Heroku 中 redis 6 连接失败的问题
    # ref: https://github.com/chatwoot/chatwoot/issues/2420
    # 除非明确指定 redis 验证模式为 none，否则我们将恢复为默认的“验证对等体”
    # ref: https://www.rubydoc.info/stdlib/openssl/OpenSSL/SSL/SSLContext#DEFAULT_PARAMS-constant
    ENV['REDIS_OPENSSL_VERIFY_MODE'] == 'none' ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
  end
end
