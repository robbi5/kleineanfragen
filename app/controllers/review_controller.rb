class ReviewController < ApplicationController
  def index
  end

  def papers
    @incomplete = {}
    Body.find_each do |b|
      @incomplete[b.state] = []
      @incomplete[b.state].concat Paper.where(body: b).where(['published_at > ?', Date.today])
      @incomplete[b.state].concat Paper.where(body: b, page_count: nil).limit(50)
      @incomplete[b.state].concat Paper.find_by_sql(
        ['SELECT p.* FROM papers p ' \
          "LEFT OUTER JOIN paper_originators o ON (o.paper_id = p.id AND o.originator_type = 'Person') " \
          "WHERE p.body_id = ? AND p.doctype != ? AND o.id IS NULL", b.id, Paper::DOCTYPE_MAJOR_INTERPELLATION]
      )
      @incomplete[b.state].concat Paper.find_by_sql(
        ['SELECT p.* FROM papers p ' \
          "LEFT OUTER JOIN paper_originators o ON (o.paper_id = p.id AND o.originator_type = 'Organization') " \
          'WHERE p.body_id = ? AND o.id IS NULL', b.id]
      )
      @incomplete[b.state].concat Paper.find_by_sql(
        ['SELECT p.* FROM papers p ' \
          "LEFT OUTER JOIN paper_answerers a ON (a.paper_id = p.id AND a.answerer_type = 'Ministry') " \
          'WHERE p.body_id = ? AND a.id IS NULL', b.id]
      )
      @incomplete[b.state].uniq!
      @incomplete[b.state].keep_if { |p| p.is_answer == true }
    end
  end

  def ministries
    @ministries = Ministry.where('length(name) > 70 OR length(name) < 12')
  end

  def today
    @papers = {}
    @ministries = {}
    Body.find_each do |b|
      @papers[b.id] = b.papers.where(['created_at >= ?', Date.today])
      @ministries[b.id] = b.ministries.where(['created_at >= ?', Date.today])
    end
    @people = Person.where(['created_at >= ?', Date.today])
    @organizations = Organization.where(['created_at >= ?', Date.today])
  end
end
