# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Body.create([
  { name: 'Bayern',          state: 'BY' },
  { name: 'Berlin',          state: 'BE' },
  { name: 'Brandenburg',     state: 'BB' },
  { name: 'Bundestag',       state: 'BT' },
  { name: 'Hamburg',         state: 'HH' },
  { name: 'Rheinland-Pfalz', state: 'RP' }
])

berlin = Body.find_by_name('Berlin')
Ministry.create([
  { body: berlin, short_name: 'SenArbIntFrau',   name: 'Senatsverwaltung für Arbeit, Integration und Frauen' },
  { body: berlin, short_name: 'SenBildJugWiss',  name: 'Senatsverwaltung für Bildung, Jugend und Wissenschaft' },
  { body: berlin, short_name: 'SenFin',          name: 'Senatsverwaltung für Finanzen' },
  { body: berlin, short_name: 'SenGesSoz',       name: 'Senatsverwaltung für Gesundheit und Soziales' },
  { body: berlin, short_name: 'SenInnSport',     name: 'Senatsverwaltung für Inneres und Sport' },
  { body: berlin, short_name: 'SenJustV',        name: 'Senatsverwaltung für Justiz und Verbraucherschutz' },
  { body: berlin, short_name: 'SenStadtUm',      name: 'Senatsverwaltung für Stadtentwicklung und Umwelt' },
  { body: berlin, short_name: 'SenWiTechForsch', name: 'Senatsverwaltung für Wirtschaft, Technolgie und Forschung' }
])