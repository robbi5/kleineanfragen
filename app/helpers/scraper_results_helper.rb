module ScraperResultsHelper

  def distance_of_time_in_min_sec(from_time, to_time)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    from_time, to_time = to_time, from_time if from_time > to_time
    distance_in_minutes = ((to_time - from_time) / 60.0).floor
    distance_in_seconds = (to_time - from_time).floor - (distance_in_minutes * 60)
    prefix_seconds = distance_in_seconds < 10 ? '0' : ''

    if distance_in_minutes > 60
      distance_in_hours = ((to_time - from_time) / 60.0 / 60.0).floor
      distance_in_minutes = distance_in_minutes - (distance_in_hours * 60)
      prefix_minutes = distance_in_minutes < 10 ? '0' : ''
      "#{distance_in_hours}:#{prefix_minutes}#{distance_in_minutes}:#{prefix_seconds}#{distance_in_seconds}"
    else
      "#{distance_in_minutes}:#{prefix_seconds}#{distance_in_seconds}"
    end
  end
end
