json.url paper_url(@body, @legislative_term, @paper, format: :json)
json.html_url paper_url(@body, @legislative_term, @paper)

json.full_reference @paper.full_reference
json.legislative_term @legislative_term
json.reference @paper.reference

json.body do
  json.name @body.name
  json.state @body.state
end

json.title @paper.title

json.interpellation_type @paper.doctype
json.published_at @paper.published_at
json.page_count @paper.page_count
json.contains_table @paper.contains_table
json.contains_classified_information @paper.contains_classified_information

json.originators do
  json.people @paper.originator_people do |person|
    json.name person.name
  end
  json.organizations @paper.originator_organizations do |organization|
    json.name organization.name
    json.html_url organization_url(@body, organization)
  end
end

json.answerers do
  json.ministries @paper.answerer_ministries do |ministry|
    json.name ministry.name
    json.html_url ministry_url(@body, ministry)
  end
end

json.contents_url paper_url(@body, @legislative_term, @paper, format: :txt)
json.download_url paper_url(@body, @legislative_term, @paper, format: :pdf)

json.source_url @paper.source_url

json.related do
  json.array! @paper.paper_relations do |pr|
    json.paper do
      json.url paper_url(pr.other_paper.body, pr.other_paper.legislative_term, pr.other_paper, format: :json)
    end
    json.reason pr.reason
  end
end