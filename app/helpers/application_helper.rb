module ApplicationHelper
  def link_to_paper_url(title, paper, html_options = {})
    link_to title, paper_url(paper.body, paper.legislative_term, paper), html_options
  end

  def link_to_paper(title, paper, html_options = {})
    link_to title, paper_path(paper.body, paper.legislative_term, paper), html_options
  end

  def paper_short_url(paper)
    paper_url(paper.body, paper.legislative_term, paper).gsub(paper.friendly_id, paper.reference)
  end

  def time_ago_in_words_dativ(time)
    time_ago_in_words(time, scope: :'datetime.distance_in_words_dativ')
  end

  def display_obituary?
    Rails.application.config.x.display_obituary || (!params.nil? && params.key?(:obituary))
  end

  def display_email_subscription?
    Rails.application.config.x.enable_email_subscription
  end

  def display_header_search?
    !current_page?(root_path) && !current_page?(search_path) && !current_page?(search_advanced_path)
  end

  def feed_url_with_current_page(model, params = {})
    options = params.merge(only_path: false, format: 'atom')
    options[:page] = model.current_page if model.current_page > 1
    url_for(options)
  end

  def paginated_feed(feed, model, params = {})
    options = params.merge(only_path: false, format: 'atom')
    unless model.first_page?
      prev_url = if model.prev_page == 1
                   url_for(options)
                 else
                   url_for(options.merge(page: model.prev_page))
                 end
      feed.link(rel: 'prev', type: 'application/atom+xml', href: prev_url)
    end
    unless model.last_page?
      next_url = url_for(options.merge(page: model.next_page))
      feed.link(rel: 'next', type: 'application/atom+xml', href: next_url)
    end
  end

  def relative_time_dativ(time)
    time_tag(time, time_ago_in_words_dativ(time), title: time)
  end

  def body_with_prefix(body)
    (body.state == 'BT' ? 'dem ' : '') + body.name
  end
end