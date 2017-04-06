class ReviewController < ApplicationController
  def index
  end

  def papers
    @incomplete = {}
    @count = 0
    Body.find_each do |b|
      @incomplete[b.state] = []
      @incomplete[b.state].concat Paper.where(body: b).where(['published_at > ?', Date.today])
      @incomplete[b.state].concat Paper.where(body: b, page_count: nil).limit(50)
      @incomplete[b.state].concat Paper.where(body: b, contents: nil).limit(50)
      @incomplete[b.state].concat Paper.find_by_sql(
        ['SELECT p.* FROM papers p ' \
          "LEFT OUTER JOIN paper_originators o ON (o.paper_id = p.id AND o.originator_type = 'Person') " \
          'WHERE p.body_id = ? AND p.doctype != ? AND p.frozen_at IS NULL AND o.id IS NULL', b.id, Paper::DOCTYPE_MAJOR_INTERPELLATION]
      )
      @incomplete[b.state].concat Paper.find_by_sql(
        ['SELECT p.* FROM papers p ' \
          "LEFT OUTER JOIN paper_originators o ON (o.paper_id = p.id AND o.originator_type = 'Organization') " \
          'WHERE p.body_id = ? AND p.frozen_at IS NULL AND o.id IS NULL', b.id]
      )
      @incomplete[b.state].concat Paper.find_by_sql(
        ['SELECT p.* FROM papers p ' \
          "LEFT OUTER JOIN paper_answerers a ON (a.paper_id = p.id AND a.answerer_type = 'Ministry') " \
          'WHERE p.body_id = ? AND p.frozen_at IS NULL AND a.id IS NULL', b.id]
      )
      @incomplete[b.state].uniq!
      @incomplete[b.state].keep_if { |p| p.is_answer == true && !p.frozen? && p.problems.size > 0 }
      @count += @incomplete[b.state].size
    end
  end

  def ministries
    @ministries = Ministry.where('length(name) > 70 OR length(name) < 12')
  end

  def late
    @papers = Paper.unscoped.where(is_answer: false).where(['created_at <= ?', Date.today - 4.weeks]).order('created_at ASC')
    @count = @papers.size
  end

  def today
    @papers = {}
    @ministries = {}
    Body.find_each do |b|
      @papers[b.id] = b.papers.where(['created_at >= ?', Date.today])
      @ministries[b.id] = b.ministries.where(['created_at >= ?', Date.today])
    end
    @count = @papers.values.map(&:size).reduce(&:+)
    @people = Person.where(['created_at >= ?', Date.today])
    @organizations = Organization.where(['created_at >= ?', Date.today])
  end

  def relations
    @papers = Paper.joins(:paper_relations)
              .group('papers.id') # :paper_id doesn't work
              .having('count(paper_relations.id)>0')
              .order(id: :desc)
              .page params[:page]
    @reference_lines = {}
    @papers.each do |paper|
      id = paper.id
      known_references = paper.related_papers.map(&:full_reference)
      lines = paper.contents.scan(/.{1,55}\D{5}\d{1,2}\/[\d\s]+.{1,60}/)
              .reject { |l| l.include? paper.full_reference }
              .map do |l|
                m = l.strip.match(/(\d{1,2}\/[\d\s]+)/)
                full_reference = m[1].gsub(/\s/, '')
                cls = known_references.include?(full_reference) ? 'known' : ''
                s = l.strip.split(m[1])
                line = ''.html_safe << s[0] << "<mark class='#{cls}'>#{m[1]}</mark>".html_safe << s[1]
                [full_reference, line]
              end
      @reference_lines[id] ||= []
      @reference_lines[id].concat Hash[lines].values # lazy uniq
    end
  end
end
