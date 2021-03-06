require 'test_helper'

class ExtractRelatedPapersJobTest < ActiveSupport::TestCase
  test 'in der Kleinen Anfrage "Großraubtiermanagement in Hessen" (Drucksache 19/1767)' do
    text = 'Unklarheiten in der Kleinen Anfrage "Großraubtiermanagement in Hessen" (Drucksache 19/1767) und'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['19/1767'], references
  end

  test 'in der Kleinen Anfrage „Prozesskostenhilfe in Berlin – wie weit ist die Arbeitsgruppe?“ (Drucksache 17/11424)' do
    text = 'in der Kleinen Anfrage „Prozesskostenhilfe in Berlin – wie weit ist die Arbeitsgruppe?“ (Drucksache 17/11424) erwähnten'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/11424'], references
  end

  test 'in der Kleinen Anfrage: „Wirtschaftlichkeit des Projektes PROFI“ vom 6. Februar 2013 (Drs. 18/461)' do
    text = 'Frage 1: In der Kleinen Anfrage: „Wirtschaftlichkeit des Projektes PROFI“ vom 6. Februar 2013 (Drs. 18/461)'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['18/461'], references
  end

  test 'in der kleinen Anfrage (Drucksache 18/534)' do
    text = 'hat in der kleinen Anfrage (Drucksache 18/534) hinsichtlich'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['18/534'], references
  end

  test 'in der Kleinen Anfrage (Drs.: 17/14681)' do
    text = 'die in der Kleinen Anfrage (Drs.: 17/14681) verkehrsplanerisch'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/14681'], references
  end

  test 'in der Kleinen Anfrage (DS 6/484)' do
    text = 'In der kleinen Anfrage (DS 6/484) hat'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/484'], references
  end

  test 'in der Kleinen Anfrage 17/11023' do
    text = 'die Tabelle in der Kleinen Anfrage 17/11023 aktualisieren'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/11023'], references
  end

  test 'in der Kleinen Anfrage Drs.-Nr.: 6/1905' do
    text = 'In der Kleinen Anfrage Drs.-Nr.: 6/1905 teilen'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/1905'], references
  end

  test 'in der Kleinen Anfrage Drs.Nr. 17/10014' do
    text = 'als in der Kleinen Anfrage Drs.Nr. 17/10014'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/10014'], references
  end

  test 'in der Kleinen Anfrage (KA) 17/12415' do
    text = 'in der Kleinen Anfrage (KA) 17/12415 geschilderten'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/12415'], references
  end

  test 'in der Kleinen Anfrage/Drucksache 18/171' do
    text = 'Wahlperiode 2 in der Kleinen Anfrage/Drucksache 18/171 vom'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['18/171'], references
  end

  test 'in der Kleinen Anfrage Drucksache 19/2370' do
    text = 'bereits in der Kleinen Anfrage Drucksache 19/2370 mitgeteilt'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['19/2370'], references
  end

  test 'bezieht sich auf Drucksache 6/1722' do
    text = 'Die Kleine Anfrage bezieht sich auf Drucksache 6/1722. '
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/1722'], references
  end

  test 'in der Kleinen Anfrage 17/13 032' do
    text = 'Wie schon in der Kleinen Anfrage 17/13 032 mitgeteilt'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/13032'], references
  end

  test 'in der Kleinen Anfrage 1400' do
    text = 'wie in der Kleinen Anfrage 1400 beschrieben'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['1400'], references
  end

  test 'in der Kleinen Anfrage Nr. 17/11016' do
    text = 'In der Kleinen Anfrage Nr. 17/11016 zu'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/11016'], references
  end

  test 'in der Kleinen Anfrage Drs. 6/292' do
    text = 'In der Kleinen Anfrage Drs. 6/292 wurde'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/292'], references
  end

  test 'in der Kleinen Anfrage Drucksache 16/3853' do
    text = 'in der Kleinen Anfrage Drucksache 16/3853 des'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/3853'], references
  end

  test 'in der Kleinen Anfrage Drs 6/292' do
    text = 'in der Kleinen Anfrage Drs 6/292 wurde'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/292'], references
  end

  test 'in der Kleinen Anfrage, Drs. 17/11550' do
    text = 'Tabelle in der Kleinen Anfrage, Drs. 17/11550 ergänzen.'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/11550'], references
  end

  test 'in der Kleinen Anfrage, Drs 17/11036' do
    text = 'Tabelle in der Kleinen Anfrage, Drs 17/11036 fortsetzen'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/11036'], references
  end

  test 'In der Kleinen Anfrage mit der Drucksachen- Nr.:17/11416' do
    text = 'In der Kleinen Anfrage mit der Drucksachen- Nr.:17/11416 wird'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/11416'], references
  end

  test 'in der Kleinen Anfrage zur schriftlichen Beantwortung (Drucksache 17/3767)' do
    text = 'In der Kleinen Anfrage zur schriftlichen Beantwortung (Drucksache 17/3767) der '
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/3767'], references
  end

  test 'in der Kleinen Anfrage 2484 (Drucksache 16/6303)' do
    text = 'In der Kleinen Anfrage 2484 (Drucksache 16/6303) wollten'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/6303'], references
  end

  test 'in der Kleinen Anfrage (LT-DRS 16/3914)' do
    text = 'Fragen in der Kleinen Anfrage (LT-DRS 16/3914) zu'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/3914'], references
  end

  test 'in der Kleinen Anfrage des Abgeordneten Wedel – Drucksache 16/2191' do
    text = 'Wie bereits in der Kleinen Anfrage des Abgeordneten Wedel – Drucksache 16/2191 – angefragt'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/2191'], references
  end

  test 'in der Kleinen Anfrage vom 2. April 2008 (Drucksache 15/2074)' do
    text = 'in der Kleinen Anfrage vom 2. April 2008 (Drucksache 15/2074) verwiesen'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['15/2074'], references
  end

  test 'in der kleinen Anfrage vom 10. August 2012 (DS 17/10837)' do
    text = 'In der kleinen Anfrage vom 10. August 2012 (DS 17/10837) hatte'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/10837'], references
  end

  test 'in der Kleinen Anfrage vom 07.02.2012, Drucksache 6/284' do
    text = 'Landesregierung In der Kleinen Anfrage vom 07.02.2012, Drucksache 6/284, wurde'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/284'], references
  end

  test 'in der Kleinen Anfrage 3032 (Drucksachen 16/7748 und 16/7912)' do
    text = 'Bereits in der Kleinen Anfrage 3032 (Drucksachen 16/7748 und 16/7912) habe'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/7748', '16/7912'], references
  end

  test 'in der Kleinen Anfrage ,Drs 6/96' do
    text = 'Frage 4 in der Kleinen Anfrage ,Drs 6/96 Umsetzung'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/96'], references
  end

  test 'in der Kleinen Anfrage 1447 (LT-Drs. 16/3602)' do
    text = 'Fragen in der Kleinen Anfrage 1447 (LT-Drs. 16/3602) zur'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/3602'], references
  end

  test 'der Kleinen Anfrage 2524 (Drucksache 16/3917)' do
    text = 'die Beantwortung der Kleinen Anfrage 2524 (Drucksache 16/3917) verwiesen.'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/3917'], references
  end

  test 'in der Drucksache 6/3045, auf Drucksache 6/2703' do
    text = 'Bezogen auf die Antwort zu Frage 1 in der Drucksache 6/3045 und den Verweis auf die Kleine Anfrage vom 3. März 2014 auf Drucksache 6/2703: I'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/3045', '6/2703'], references
  end

  test 'zur Kleinen Anfrage auf Drucksache 6/2292' do
    text = 'Die Angaben für das Schuljahr 2012/13 wurden bereits in der Antwort zur Kleinen Anfrage auf Drucksache 6/2292 vom 13.11.2013 übermittelt.'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/2292'], references
  end

  test 'in Drucksache 6/1686, 6/2198 und 6/2691' do
    text = 'Der Landesregierung liegen ergänzend zu den in Drucksache 6/1686, 6/2198 und 6/2691 mitgeteilten Informationen'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/1686', '6/2198', '6/2691'], references
  end

  test 'in der Kleinen Anfrage der Abgeordneten ... Drucksache 6/2703' do
    text = 'Es wird auf die Antwort zu Frage 1 in der Kleinen Anfrage der Abgeordneten Simone Oldenburg und Torsten Koplin, Fraktion DIE LINKE, vom 3. März 2014, Drucksache 6/2703, verwiesen.'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/2703'], references
  end

  test 'auf die Kleine Anfrage/Drucksache 18/67' do
    text = 'Wie bereits in der Antwort auf die Kleine Anfrage/Drucksache 18/67 vom 01.08.2012 ausgeführt'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['18/67'], references
  end

  test 'Antwort auf eine Kleine Anfrage, Drucksache 16/2703' do
    text = 'Antwort auf eine Kleine Anfrage, Drucksache 16/2703'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/2703'], references
  end

  test 'der Kleinen Anfrage 841, Landtags-Drucksache 16/1308' do
    text = 'Wie bereits in der Beantwortung der Kleinen Anfrage 841, Landtags-Drucksache 16/1308, ausgeführt,'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/1308'], references
  end

  test 'der Kleinen Anfrage 2882 unter der Drucksache 16/4408' do
    text = 'auf die Antwort der Kleinen Anfrage 2882 unter der Drucksache 16/4408 stelle ich folgende weitere Fragen'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/4408'], references
  end

  test 'Antwort zu 4. in 17/16265' do
    text = 'werden (Antwort zu 4. in 17/16265),'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/16265'], references
  end

  test 'Antwort zu 4./5. in 17/13120' do
    text = 'erforderlich (Antwort zu 4./5. in 17/13120)?'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['17/13120'], references
  end

  test 'In Landtags-Drucksache 16/3181' do
    text = 'In Landtags-Drucksache 16/3181 vom 4. Juni 2013 hatte'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/3181'], references
  end

  test 'die Kleine Anfrage (Drs.-Nr. 16/1328 „...“' do
    text = 'auf die Kleine Anfrage (Drs.-Nr. 16/1328 „Welche Zukunft hat das Projekt „Jedem Kind ein Instrument“) erläutert'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/1328'], references
  end

  test 'die Anfrage „...“ (LT-DS 16/3308)' do
    text = 'die Anfrage „Häufige Kostenexplosion bei...plant?“ (LT-DS 16/3308)'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/3308'], references
  end

  test 'Antwort (Drucksache 16/3052)' do
    text = 'Die Landesregierung teilte in ihrer Antwort (Drucksache 16/3052) mit, dass die Rücklagen'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/3052'], references
  end

  test 'in der Kleinen Anfrage 3837 (Drs. 14/10833 vom 18. März 2010)' do
    text = 'in der Kleinen Anfrage 3837 (Drs. 14/10833 vom 18. März 2010) nach'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['14/10833'], references
  end

  test 'den Schriftlichen Kleinen Anfragen 21/84' do
    text = 'sowie den Schriftlichen Kleinen Anfragen 21/84 (Vorbereitung auf'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['21/84'], references
  end

  test 'die Drs. 21/2057' do
    text = 'Dies betraf die Drs. 21/2057 (Sanierung'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['21/2057'], references
  end

  test 'der Drs. 21/1464' do
    text = 'im Falle der Drs. 21/1464 ergänzend'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['21/1464'], references
  end

  test 'in den Drucksachen 15/5899' do
    text = 'Wie bereits in den Drucksachen 15/5899 vom'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['15/5899'], references
  end

  test 'auf die Beantwortung der Kleinen Anfrage LT-Nr. KA 6/8670' do
    text = 'auf die Beantwortung der Kleinen Anfrage LT-Nr. KA 6/8670,'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/8670'], references
  end

  test 'in der Beantwortung der KA 6/8670' do
    text = 'In der Beantwortung der KA 6/8670 fiel'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/8670'], references
  end

  test 'Antwort der Landesregierung (Drs. 6/5489)' do
    text = 'seit der Antwort der Landesregierung (Drs. 6/5489) auf die damalige Anfrage'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['6/5489'], references
  end

  #
  # major interpellations
  #

  test 'In der Großen Anfrage 1 der Fraktion der PIRATEN; Drucksache 16/763' do
    text = 'In der Großen Anfrage 1 der Fraktion der PIRATEN; Drucksache 16/763'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal ['16/763'], references
  end

  #
  # negative tests:
  #

  test 'in der Kleinen Anfrage vorgegeben' do
    text = 'wie in der Kleinen Anfrage vorgegeben'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal [], references
  end

  test 'in der Kleinen Anfrage unter 1. bis 9. benannten' do
    text = 'in der Kleinen Anfrage unter 1. bis 9. benannten'
    references = ExtractRelatedPapersJob.extract_contents(text)
    assert_equal [], references
  end

  #
  # titles
  #

  test 'Nachfrage zur Schriftlichen Anfrage 17/17377' do
    title = 'Nachfrage zur Schriftlichen Anfrage 17/17377'
    references = ExtractRelatedPapersJob.extract_title(title)
    assert_equal ['17/17377'], references
  end

  test 'Nachfrage zu den Antworten auf die Kleinen Anfragen (Drucksache 6/1809 und 6/1131)' do
    title = 'Nachfrage zu den Antworten auf die Kleinen Anfragen (Drucksache 6/1809 und 6/1131)'
    references = ExtractRelatedPapersJob.extract_title(title)
    assert_equal ['6/1809', '6/1131'], references
  end

  test 'Unklarheiten in der Kleinen Anfrage "Großraubtiermanagement in Hessen" 19/1767' do
    title = 'Unklarheiten in der Kleinen Anfrage "Großraubtiermanagement in Hessen" 19/1767'
    references = ExtractRelatedPapersJob.extract_title(title)
    assert_equal ['19/1767'], references
  end

  test 'Nachfrage zu Drs. 6/4698' do
    title = 'Befreiung von den Kostenbeiträgen im Rahmen der Kinderbetreuung - Nachfrage zu Drs. 6/4698'
    references = ExtractRelatedPapersJob.extract_title(title)
    assert_equal ['6/4698'], references
  end

end