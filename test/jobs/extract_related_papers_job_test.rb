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

end