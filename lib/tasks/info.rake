task :ruby_version do
  logger = Logger.new(Rails.root.join('log/info.log'))
  logger.info({
    path: RbConfig.ruby,
    version: RUBY_VERSION,
  }.to_json)
end
