module ApplicationHelper
  def link_to_paper(title, paper, html_options = {})
    link_to title, paper_path(paper.body, paper.legislative_term, paper), html_options
  end

  def paper_short_url(paper)
    paper_url(paper.body, paper.legislative_term, paper).gsub(paper.friendly_id, paper.reference)
  end

  def time_ago_in_words_dativ(time)
    time_ago_in_words(time, scope: :'datetime.distance_in_words_dativ')
  end

  def display_header_search?
    !current_page?(root_path) && !current_page?(search_path)
  end

  def feed_url_with_current_page(model)
    return url_for(only_path: false, format: 'atom') if model.current_page == 1
    url_for(only_path: false, format: 'atom', page: model.current_page)
  end

  def paginated_feed(feed, model)
    unless model.first_page?
      prev_url = if model.prev_page == 1
                   url_for(only_path: false, format: 'atom')
                 else
                   url_for(only_path: false, format: 'atom', page: model.prev_page)
                 end
      feed.link(rel: 'prev', type: 'application/atom+xml', href: prev_url)
    end
    unless model.last_page?
      next_url = url_for(only_path: false, format: 'atom', page: model.next_page)
      feed.link(rel: 'next', type: 'application/atom+xml', href: next_url)
    end
  end

  def relative_time_dativ(time)
    time_tag(time, time_ago_in_words_dativ(time))
  end
end
