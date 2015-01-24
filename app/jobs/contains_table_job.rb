class ContainsTableJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    logger.info "Looking for Tables in Paper [#{paper.body.state} #{paper.full_reference}]"
    probability = 0.0

    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank?

    # Hint 1: "<synonym für nachfolgende> Tabelle"
    if paper.contents.match(/(?:[bB]eiliegende|beigefügte|anliegende|[Ff]olgende|nachstehende|unten stehende)[nr]? Tabelle/)
      probability += 1
    end

    # Hint 2: "Tabelle \d zeigt", "siehe Tabelle \d", "siehe Tabelle in Anlage"
    if paper.contents.match(/Tabelle \d zeigt/) || paper.contents.match(/siehe Tabelle (?:\d|in Anlage)/)
      probability += 1
    end

    # Hint 3: (Tabelle 1) ... (Tabelle 2)
    if paper.contents.match(/\(Tabelle \d\)/)
      probability += 1
    end

    # Hint 4: \d\n\d\n\d\n...
    if paper.contents.match(/(\d[\d\s]+\n[\d][\s\d]+)+/m)
      # TODO: count matches, add to probability
      probability += 0.5
    end

    logger.info "Probability of Table(s) in Paper [#{paper.body.state} #{paper.full_reference}]: #{probability}"

    paper.contains_table = probability >= 1
    paper.save
  end
end