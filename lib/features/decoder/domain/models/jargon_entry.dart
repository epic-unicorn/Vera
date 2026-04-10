/// Domain model for a medical jargon entry with plain-language Dutch translation.
library jargon_entry;

class JargonEntry {
  const JargonEntry({
    required this.term,
    required this.dutchExplanation,
    required this.actionItem,
    this.category = '',
    this.fhirCode,
    this.iknlRef,
  });

  /// The technical medical term (English or Latin).
  final String term;

  /// Plain-Dutch explanation for the patient.
  final String dutchExplanation;

  /// Concrete action item the patient can take.
  final String actionItem;

  final String category;
  final String? fhirCode;
  final String? iknlRef;
}

/// Built-in Dutch oncology glossary seeded from IKNL/NKI terminology.
const List<JargonEntry> builtInGlossary = [
  JargonEntry(
    term: 'HER2-positief',
    dutchExplanation:
        'Uw tumor maakt veel HER2-eiwit aan. Dit eiwit stimuleert de celgroei. '
        '"Positief" betekent dat de tumor gevoelig is voor HER2-remmers zoals trastuzumab.',
    actionItem:
        'Vraag uw oncoloog of trastuzumab (Herceptin) onderdeel is van uw behandelplan.',
    category: 'biomarker',
    fhirCode: 'LOINC:18474-7',
    iknlRef: 'https://www.iknl.nl/richtlijnen/borstkanker',
  ),
  JargonEntry(
    term: 'ER-negatief',
    dutchExplanation: 'Uw tumor heeft geen oestrogeenreceptoren. '
        'Dit betekent dat hormoontherapie (zoals tamoxifen) voor ú niet effectief is.',
    actionItem:
        'Bevestig met uw arts dat hormonale behandeling niet geïndiceerd is voor uw tumor.',
    category: 'biomarker',
    fhirCode: 'LOINC:85319-2',
  ),
  JargonEntry(
    term: 'Ki-67',
    dutchExplanation:
        'Ki-67 is een maat voor hoe snel de tumorcellen zich delen. '
        'Een hoge Ki-67 (≥25%) betekent een sneller groeiende tumor die vaak '
        'goed reageert op chemotherapie.',
    actionItem: 'Vraag wat uw Ki-67-percentage betekent voor uw behandelkeuze.',
    category: 'pathologie',
    fhirCode: 'LOINC:85326-7',
  ),
  JargonEntry(
    term: 'Invasief ductaal carcinoom',
    dutchExplanation:
        'Een kwaadaardige tumor die is ontstaan in de melkgangen van de borst '
        'en die de grens van de gang is doorgegroeid naar het omliggende borstweefsel.',
    actionItem:
        'Vraag naar de exacte grootte (T-stadium) en of de randen (marges) vrij zijn na operatie.',
    category: 'diagnose',
    fhirCode: 'SNOMED:783541009',
  ),
  JargonEntry(
    term: 'Stadium IIA',
    dutchExplanation: 'Stadium IIA (cT2N0M0) betekent: tumor tussen 2 en 5 cm, '
        'geen bewijs van uitzaaiing naar lymfeklieren of andere organen.',
    actionItem:
        'Vraag hoe het stadium uw behandelopties beïnvloedt en wat de te verwachten '
        'behandelcyclus is.',
    category: 'stadiëring',
    iknlRef: 'https://www.iknl.nl/richtlijnen/borstkanker',
  ),
  JargonEntry(
    term: 'Schildwachtklierprocedure (SLNB)',
    dutchExplanation:
        'Hierbij wordt de eerste lymfeklier waarop de tumor uitstroomt verwijderd '
        'en onderzocht. Is deze klier vrij van kankercellen, dan is een volledige '
        'okselkliertoilet meestal niet nodig.',
    actionItem:
        'Vraag of uw schildwachtklier vrij was (pN0 SN) en wat dit betekent voor uw prognose.',
    category: 'procedure',
    iknlRef: 'https://www.iknl.nl/richtlijnen/borstkanker',
  ),
  JargonEntry(
    term: 'Borstsparende chirurgie (BCS)',
    dutchExplanation:
        'Operatie waarbij alleen de tumor en een randje gezond weefsel worden verwijderd, '
        'gevolgd door bestraling van de resterende borst.',
    actionItem:
        'Bespreek of u in aanmerking komt voor BCS, anders voor een borstamputatie (mastectomie).',
    category: 'procedure',
    iknlRef: 'https://www.iknl.nl/richtlijnen/borstkanker',
  ),
  JargonEntry(
    term: 'Hypofractionering',
    dutchExplanation:
        'Een bestralingsschema met minder maar iets hogere doses per sessie. '
        'Bijv. 40 Gy in 15 fracties over 3 weken i.p.v. 50 Gy in 25 fracties over 5 weken.',
    actionItem:
        'Vraag hoeveel bestralingsafspraken u totaal heeft en welke bijwerkingen verwacht worden.',
    category: 'radiotherapie',
    iknlRef: 'https://www.iknl.nl/richtlijnen/borstkanker',
  ),
  JargonEntry(
    term: 'LVEF (linker ventrikel ejectiefractie)',
    dutchExplanation: 'De LVEF meet hoe goed uw hart bloed rondpompt. '
        'Trastuzumab kan de hartfunctie beïnvloeden; '
        'uw LVEF wordt daarom elke 3 maanden gemeten via echografie.',
    actionItem:
        'Zorg dat u uw echocardiografie-afspraken bijhoudt tijdens trastuzumab-behandeling.',
    category: 'cardiologie',
    iknlRef: 'https://www.iknl.nl/richtlijnen/borstkanker',
  ),
  JargonEntry(
    term: 'pCR (pathologisch complete respons)',
    dutchExplanation:
        'Pathologisch complete respons betekent dat er geen levende tumorcellen meer '
        'gevonden worden in het verwijderde weefsel na neoadjuvante therapie. '
        'pCR is geassocieerd met een gunstigere uitkomst.',
    actionItem:
        'Vraag uw arts wat pCR voor ú betekent en of het behandelplan hierdoor verandert.',
    category: 'respons',
    iknlRef: 'https://www.iknl.nl/richtlijnen/borstkanker',
  ),
];
