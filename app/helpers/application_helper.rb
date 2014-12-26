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
end
