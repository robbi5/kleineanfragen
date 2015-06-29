Abbyy.configure do |config|
  config.application_id = (ENV['ABBYY_APPLICATION_ID'] || '')
  config.password = (ENV['ABBYY_APPLICATION_PASSWORD'] || '')
end