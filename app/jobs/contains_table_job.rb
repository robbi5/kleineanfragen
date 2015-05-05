class ContainsTableJob < PaperJob
  queue_as :meta

  def perform(paper)
    logger.info "Looking for Tables in Paper [#{paper.body.state} #{paper.full_reference}]"
    probability = 0.0

    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank?

    # Hint 1: "<synonym für nachfolgende> Tabelle"
    if paper.contents.match(/(?:[bB]eiliegende|beigefügte|anliegende|[Ff]olgende|vorstehende|nachstehende|unten stehende)[nr]? Tabelle/)
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

    # Hint 4: "die Tabellen 1 bis 4"
    if paper.contents.match(/[Dd]ie Tabellen \d bis \d/)
      probability += 1
    end

    # Hint 5: "\nTabelle 2:\n"
    if paper.contents.match(/\nTabelle \d:\n/)
      probability += 1
    end

    # Hint 6: \d\n\d\n\d\n...
    if paper.contents.match(/(\d[\d\s]+\n[\d][\s\d]+)+/m)
      # TODO: count matches, add to probability
      probability += 0.5
    end

    # Hint 7: Anlage 3 Tabelle 1
    if paper.contents.match(/Anlage\s+\d+\s+Tabelle\s+\d+/m)
      probability += 1
    end

    logger.info "Probability of Table(s) in Paper [#{paper.body.state} #{paper.full_reference}]: #{probability}"

    paper.contains_table = probability >= 1
    paper.save
  end
end