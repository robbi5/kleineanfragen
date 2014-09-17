module ApplicationHelper

  def link_to_paper(title, paper, html_options={})
    link_to title, paper_path(paper.body, paper.legislative_term, paper), html_options
  end

end
