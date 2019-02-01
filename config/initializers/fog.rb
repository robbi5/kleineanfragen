require 'fog/aws'
require 'fog/aws/models/storage/file'

module AppStorage
  class << self
  attr_accessor :storage, :bucket, :initialized

  def initialize!
    return if @initialized
    fog_config = YAML.load(ERB.new(File.read("#{Rails.root}/config/fog.yml")).result)[Rails.env].to_options
    bucket = fog_config.delete :bucket

    begin
      self.storage = Fog::Storage.new(fog_config)
    rescue => error
      Rails.logger.error "Cannot initialize AppStorage: #{error}"
      return
    end
    return unless storage

    begin
      self.bucket = storage.directories.get(bucket)
      # create bucket in development mode
      if bucket.nil? && Rails.env.development?
        self.bucket = storage.directories.create(key: bucket, public: true)
      end
    rescue => error
      Rails.logger.error "Cannot initialize AppStorage/Bucket: #{error}"
      return
    end

    @initialized = true
  end

  def acl_support?
    ActiveRecord::Type::Boolean.new.cast(ENV.fetch('S3_ACL_SUPPORT', 'false'))
  end

  end
end

AppStorage.initialize! unless ENV['RACK_ENV'].nil?

if !AppStorage.acl_support?
  # Patch File, minio doesn't support acl queries
  Fog::Storage::AWS::File.class_eval do
    def public?
      true
    end
  end
end