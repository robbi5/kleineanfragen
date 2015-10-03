module PaperHelper
  def report_enabled?
    !Rails.configuration.x.report_slack_webhook.blank?
  end
end
