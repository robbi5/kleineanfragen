class EmailTokenConstraint
  def self.matches?(request)
    return false if Rails.configuration.x.email_token.blank?
    return false if request.query_parameters['token'].blank?

    ActiveSupport::SecurityUtils.variable_size_secure_compare(
      Rails.configuration.x.email_token, request.query_parameters['token']
    )
  end
end