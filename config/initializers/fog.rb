fog_config = YAML.load(ERB.new(File.read("#{Rails.root}/config/fog.yml")).result)[Rails.env].to_options
bucket = fog_config.delete :bucket

module AppStorage
  class << self
    attr_accessor :storage, :bucket
  end
end

begin
  AppStorage.storage = Fog::Storage.new(fog_config)
rescue => error
  Rails.logger.error "Cannot initialize AppStorage: #{error}"
end

if AppStorage.storage
  begin
    AppStorage.bucket = AppStorage.storage.directories.get(bucket)
    # create bucket in development mode
    if AppStorage.bucket.nil? && Rails.env.development?
      AppStorage.bucket = AppStorage.storage.directories.create(key: bucket, public: true)
    end
  rescue => error
    Rails.logger.error "Cannot initialize AppStorage/Bucket: #{error}"
  end
end