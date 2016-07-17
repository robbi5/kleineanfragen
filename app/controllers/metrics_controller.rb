class MetricsController < ApplicationController
  METRIC = Struct.new(:key, :value)

  def show
    metrics = []

    # papers_all_count
    metrics << m('papers_all_count', Paper.count)

    # ministries_all_count
    metrics << m('ministries_all_count', Ministry.count)

    # papers_body_count
    # ministries_body_count
    Body.all.each do |body|
      metrics << m("papers_#{body.state.downcase}_count", body.papers.count)
      metrics << m("ministries_#{body.state.downcase}_count", body.ministries.count)
    end

    # people_count
    metrics << m('people_count', Person.count)

    response.headers['Content-Type'] = 'text/plain; version=0.0.4'
    render plain: render_metrics(metrics)
  end

  private

  def render_metrics(metrics)
    arr = metrics.sort { |a,b| a.key <=> b.key }.map do |metric|
      [metric.key, metric.value].join ' '
    end
    arr.join("\n") + "\n"
  end

  def m(key, value)
    METRIC.new(key, value)
  end
end
