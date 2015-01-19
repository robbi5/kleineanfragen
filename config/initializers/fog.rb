fog_config = YAML.load(ERB.new(File.read("#{Rails.root}/config/fog.yml")).result)[Rails.env].to_options
bucket = fog_config.delete :bucket

module AppStorage
  class << self
    attr_accessor :storage, :bucket
  end
end

begin
  AppStorage.storage = Fog::Storage.new(fog_config)
  AppStorage.bucket = AppStorage.storage.directories.get(bucket)
rescue => error
  Rails.logger.error "Cannot initialize AppStorage: #{error}"
end