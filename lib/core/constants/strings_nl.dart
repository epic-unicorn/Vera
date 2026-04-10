/// All Dutch UI strings for Vera (NL-NL).
/// A single source of truth – no hard-coded copy in widgets.
library strings_nl;

class StringsNl {
  StringsNl._();

  // ── App ──────────────────────────────────────────────────────────────────
  static const String appName = 'Vera';
  static const String appTagline =
      'Jouw persoonlijke oncologie kompas';

  // ── Privacy Sentinel ──────────────────────────────────────────────────────
  static const String sentinelLocalTitle = 'Gegevens lokaal beveiligd';
  static const String sentinelLocalSubtitle =
      'Geen medische gegevens hebben uw apparaat verlaten.';
  static const String sentinelWarningTitle = 'Let op: Gegevensstroom actief';
  static const String sentinelWarningSubtitle =
      'Versleutelde P2P-sessie actief. Geen gegevens via server.';
  static const String sentinelErrorTitle = 'Privacy-status onbekend';
  static const String sentinelErrorSubtitle =
      'Controleer eventuele netwerkverbindingen.';

  // ── Auth ─────────────────────────────────────────────────────────────────
  static const String authTitle = 'Ontgrendel Vera';
  static const String authBiometricPrompt =
      'Gebruik uw biometrische gegevens om uw Vera kluis te openen';
  static const String authPinLabel = 'PIN-code';
  static const String authPinHint = 'Voer uw 6-cijferige PIN in';
  static const String authUnlockButton = 'Ontgrendelen';
  static const String authFailedMessage =
      'Verificatie mislukt. Pogingen resterend: ';
  static const String authSelfDestructWarning =
      'WAARSCHUWING: Na nog één mislukte poging wordt de kluis gewist.';
  static const String authSelfDestructDone =
      'Kluis definitief gewist ter bescherming van uw privacy.';
  static const String authCreateVaultTitle = 'Kluis aanmaken';
  static const String authCreateVaultBody =
      'Uw medische gegevens worden versleuteld opgeslagen met AES-256. '
      'Stel een PIN of biometrie in als extra beveiligingslaag.';

  // ── Navigation ────────────────────────────────────────────────────────────
  static const String navBlueprint = 'Tijdlijn';
  static const String navDecoder = 'Decoder';
  static const String navAppointments = 'Afspraken';
  static const String navSync = 'Delen';
  static const String navSettings = 'Instellingen';

  // ── Blueprint (De Tijdlijn) ────────────────────────────────────────────────
  static const String blueprintTitle = 'Uw Tijdlijn';
  static const String blueprintSubtitle =
      'Uw diagnose afgezet tegen IKNL-richtlijnen';
  static const String blueprintPhaseCompleted = 'Afgerond';
  static const String blueprintPhaseCurrent = 'Huidig';
  static const String blueprintPhaseFuture = 'Gepland';
  static const String blueprintIknlSource = 'Bron: IKNL Richtlijnendatabase';
  static const String blueprintNoData =
      'Geen tijdlijngegevens beschikbaar. Importeer een FHIR-rapport.';

  // ── Smart System Decoder ──────────────────────────────────────────────────
  static const String decoderTitle = 'Slim Systeem Decoder';
  static const String decoderSubtitle =
      'Medische vaktaal vertaald naar begrijpelijk Nederlands';
  static const String decoderSearchHint = 'Zoek medische term…';
  static const String decoderTranslateButton = 'Vertaal lokaal';
  static const String decoderLanguageLabel = 'Doeltaal';
  static const String decoderPrivacyNote =
      'Vertaling vindt volledig op uw apparaat plaats. '
      'Geen tekst wordt naar externe servers verstuurd.';
  static const String decoderNoModelTitle = 'Taalmodel niet geladen';
  static const String decoderNoModelBody =
      'Download het taalmodel voor offline vertaling.';
  static const String decoderDownloadModel = 'Model downloaden';
  static const String decoderDownloading = 'Downloaden…';

  // ── Appointment Navigator ─────────────────────────────────────────────────
  static const String appointmentsTitle = 'Afspraak Navigator';
  static const String appointmentsSubtitle =
      'Uw gepersonaliseerde afsprakengids';
  static const String appointmentsPocketGuide = 'Genereer Pocket Gids';
  static const String appointmentsVoiceLog = 'Symptomen inspreken';
  static const String appointmentsVoiceListening = 'Luistert…';
  static const String appointmentsVoiceStop = 'Stop opname';
  static const String appointmentsSuggestedQuestions =
      'Aanbevolen vragen voor uw arts';
  static const String appointmentsNoAppointments =
      'Geen aankomende afspraken gevonden.';

  // ── Sync (WebRTC viewer) ──────────────────────────────────────────────────
  static const String syncTitle = 'Veilig Delen';
  static const String syncSubtitle =
      'Deel uw tijdlijn via een beveiligde P2P-verbinding';
  static const String syncQrInstruction =
      'Scan deze QR-code met de Vera Web-viewer op een ander scherm.';
  static const String syncSessionActive = 'Sessie actief';
  static const String syncSessionExpired = 'Sessie verlopen';
  static const String syncWebViewerTitle = 'Vera – Web Viewer';
  static const String syncWebViewerBody =
      'U bekijkt live-gegevens via een versleutelde P2P-verbinding. '
      'Alle gegevens bestaan uitsluitend in het RAM-geheugen van dit tabblad '
      'en worden onmiddellijk gewist bij sluiten.';
  static const String syncScanQr = 'Scan QR-code';
  static const String syncConnecting = 'Verbinding maken…';
  static const String syncConnected = 'Verbonden';
  static const String syncDisconnected = 'Verbinding verbroken';
  static const String syncEphemeralWarning =
      'WAARSCHUWING: Sluit dit tabblad om alle gegevens te wissen.';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String settingsTitle = 'Instellingen';
  static const String settingsVault = 'Kluis & Beveiliging';
  static const String settingsWipeVault = 'Kluis wissen';
  static const String settingsWipeVaultConfirm =
      'Weet u zeker dat u alle medische gegevens wilt verwijderen? '
      'Deze actie kan niet worden teruggedraaid.';
  static const String settingsWipeVaultConfirmButton = 'Definitief wissen';
  static const String settingsCancel = 'Annuleren';
  static const String settingsAccessibility = 'Toegankelijkheid';
  static const String settingsFontSize = 'Tekstgrootte';
  static const String settingsHighContrast = 'Hoog contrast';
  static const String settingsAbout = 'Over Vera';
  static const String settingsVersion = 'Versie';
  static const String settingsPrivacyPolicy = 'Privacybeleid';
  static const String settingsOpenSource = 'Open-source licenties';

  // ── Common ────────────────────────────────────────────────────────────────
  static const String ok = 'OK';
  static const String cancel = 'Annuleren';
  static const String confirm = 'Bevestigen';
  static const String loading = 'Laden…';
  static const String error = 'Fout';
  static const String retry = 'Opnieuw proberen';
  static const String close = 'Sluiten';
  static const String save = 'Opslaan';
  static const String delete = 'Verwijderen';
  static const String search = 'Zoeken';
  static const String import = 'Importeren';
  static const String export = 'Exporteren';
  static const String source = 'Bron';
  static const String date = 'Datum';
  static const String status = 'Status';
  static const String local = 'Lokaal';
  static const String encrypted = 'Versleuteld';
  static const String privacyProtected = 'Privacy beschermd';

  // ── FHIR / Medical ───────────────────────────────────────────────────────
  static const String fhirDiagnosis = 'Diagnose';
  static const String fhirProcedure = 'Behandeling';
  static const String fhirMedication = 'Medicatie';
  static const String fhirObservation = 'Bevinding';
  static const String fhirCarePlan = 'Zorgplan';
  static const String fhirPatient = 'Patiënt (geanonimiseerd)';
  static const String fhirLastUpdated = 'Laatste update';
  static const String fhirStatus = 'Status';
  static const String fhirIknlGuideline = 'IKNL Richtlijn';
}
