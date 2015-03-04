# overriding GlobalID default locator to use unscoped model
GlobalID::Locator.use :kleineanfragen do |gid|
  Kleineanfragen.const_get(gid.model_name).unscoped.find(gid.model_id)
end