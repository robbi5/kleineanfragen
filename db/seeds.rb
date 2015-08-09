# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Body.create([
  # { name: 'Baden-Württemberg',      state: 'BW', website: 'https://www.statistik-bw.de/OPAL' },
  { name: 'Bayern',                 state: 'BY', website: 'https://www1.bayern.landtag.de/webangebot1/dokumente.suche.maske.jsp' },
  { name: 'Berlin',                 state: 'BE', website: 'https://pardok.parlament-berlin.de' },
  { name: 'Brandenburg',            state: 'BB', website: 'http://www.parldok.brandenburg.de' },
  { name: 'Bundestag',              state: 'BT', website: 'http://dipbt.bundestag.de/dip21.web' },
  { name: 'Bremen',                 state: 'HB', website: 'https://www.bremische-buergerschaft.de' },
  { name: 'Hamburg',                state: 'HH', website: 'https://www.buergerschaft-hh.de/Parldok' },
  { name: 'Hessen',                 state: 'HE', website: 'http://starweb.hessen.de/starweb/LIS/Pd_Eingang.htm' },
  { name: 'Mecklenburg-Vorpommern', state: 'MV', website: 'http://www.dokumentation.landtag-mv.de' },
  { name: 'Niedersachsen',          state: 'NI', website: 'http://www.nilas.niedersachsen.de' },
  { name: 'Nordrhein-Westfalen',    state: 'NW', website: 'https://www.landtag.nrw.de/portal/WWW/Navigation_R2010/040-Dokumente-und-Recherche/Inhalt.jsp' },
  { name: 'Rheinland-Pfalz',        state: 'RP', website: 'http://opal.rlp.de/starweb/OPAL_extern' },
  { name: 'Saarland',               state: 'SL', website: 'http://www.landtag-saar.de/Dokumente' },
  { name: 'Sachsen',                state: 'SN', website: 'http://edas.landtag.sachsen.de' },
  { name: 'Sachsen-Anhalt',         state: 'ST', website: 'http://padoka.landtag.sachsen-anhalt.de' },
  { name: 'Schleswig-Holstein',     state: 'SH', website: 'http://lissh.lvn.parlanet.de/shlt/start.html' },
  { name: 'Thüringen',              state: 'TH', website: 'http://www.parldok.thueringen.de' }
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
  { body: berlin, short_name: 'SenWiTechForsch', name: 'Senatsverwaltung für Wirtschaft, Technolgie und Forschung' },
  { body: berlin, short_name: 'Skzl',            name: 'Senatskanzlei' },
  { body: berlin, short_name: 'RBm',             name: 'Regierender Bürgermeister' }
])

nrw = Body.find_by_state('NW')
Ministry.create([
  { body: nrw, short_name: 'FM',      name: 'Finanzministerium' },
  { body: nrw, short_name: 'JM',      name: 'Justizministerium' },
  { body: nrw, short_name: 'MAIS',    name: 'Ministerium für Arbeit, Integration und Soziales' },
  { body: nrw, short_name: 'MBEM',    name: 'Ministerium für Bundesangelegenheiten, Europa und Medien' },
  { body: nrw, short_name: 'MBWSV',   name: 'Ministerium für Bauen, Wohnen, Stadtentwicklung und Verkehr' },
  { body: nrw, short_name: 'MFKJKS',  name: 'Ministerium für Familie, Kinder, Jugend, Kultur und Sport' },
  { body: nrw, short_name: 'MGEPA',   name: 'Ministerium für Gesundheit, Emanzipation, Pflege und Alter' },
  { body: nrw, short_name: 'MIK',     name: 'Ministerium für Inneres und Kommunales' },
  { body: nrw, short_name: 'MIWF',    name: 'Ministerium für Innovation, Wissenschaft und Forschung' },
  { body: nrw, short_name: 'MKULNV',  name: 'Ministerium für Klimaschutz, Umwelt, Landwirtschaft, Natur- und Verbraucherschutz' },
  { body: nrw, short_name: 'MP',      name: 'Ministerpräsident/in' },
  { body: nrw, short_name: 'MSW',     name: 'Ministerium für Schule und Weiterbildung' },
  { body: nrw, short_name: 'MWEIMH',  name: 'Ministerium für Wirtschaft, Energie, Industrie, Mittelstand und Handwerk' }
])

sachsen = Body.find_by_state('SN')
Ministry.create([
  { body: sachsen, short_name: 'SK',   name: 'Sächsische Staatskanzlei' },
  { body: sachsen, short_name: 'SMF',  name: 'Staatsministerium der Finanzen' },
  { body: sachsen, short_name: 'SMI',  name: 'Staatsministerium des Innern' },
  { body: sachsen, short_name: 'SMJ',  name: 'Staatsministerium der Justiz' },
  { body: sachsen, short_name: 'SMK',  name: 'Staatsministerium für Kultus' },
  { body: sachsen, short_name: 'SMS',  name: 'Staatsministerium für Soziales und Verbraucherschutz' },
  { body: sachsen, short_name: 'SMUL', name: 'Staatsministerium für Umwelt und Landwirtschaft' },
  { body: sachsen, short_name: 'SMWA', name: 'Staatsministerium für Wirtschaft, Arbeit und Verkehr' },
  { body: sachsen, short_name: 'SMWK', name: 'Staatsministerium für Wissenschaft und Kunst' }
])