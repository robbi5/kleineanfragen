class Report < Hash
  def initialize(created_at = nil, created_ip = nil, user_agent = nil)
    send(:[]=, :created_at, created_at.to_s)
    send(:[]=, :created_ip, created_ip)
    send(:[]=, :user_agent, user_agent)
  end
end