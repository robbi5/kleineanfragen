fog_config = YAML.load(ERB.new(File.read("#{Rails.root}/config/fog.yml")).result)[Rails.env].to_options
bucket = fog_config.delete :bucket
FogStorage = Fog::Storage.new(fog_config)
FogStorageBucket = FogStorage.directories.get(bucket)