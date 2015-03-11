class Report < Hash
  def initialize(created_at = nil, created_ip = nil, user_agent = nil)
    send(:[]=, :created_at, created_at.to_s)
    send(:[]=, :created_ip, created_ip)
    send(:[]=, :user_agent, user_agent)
  end

  def created_at
    try(:[], :created_at)
  end

  def created_ip
    try(:[], :created_ip)
  end

  def user_agent
    try(:[], :user_agent)
  end
end