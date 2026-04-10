import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/failures.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final mockDataServiceProvider = Provider<MockDataService>(
  (_) => MockDataService(),
);

// ── FHIR R4 domain objects ────────────────────────────────────────────────────

/// Thin FHIR R4 resource wrapper – deliberately lightweight to avoid pulling
/// in a full FHIR package dependency in the mock layer.
/// Production code would use the `fhir` pub package for full validation.
class FhirResource {
  const FhirResource({
    required this.resourceType,
    required this.id,
    required this.data,
  });
  final String resourceType;
  final String id;
  final Map<String, dynamic> data;
}

class FhirBundle {
  const FhirBundle({required this.resources, required this.timestamp});
  final List<FhirResource> resources;
  final String timestamp; // ISO-8601
}

// ── Service ───────────────────────────────────────────────────────────────────

/// # MockDataService
///
/// Simulates a **MedMij / HL7 FHIR R4** oncology data pull from a Dutch
/// hospital EPD (Electronic Patient Dossier). In production this would be
/// replaced by a real MedMij OAuth 2.0 + SMART-on-FHIR flow that remains
/// within the Zero-Knowledge boundary (only anonymised markers leave the
/// device; see [IdentityShieldService]).
///
/// ## Dataset
/// The mock simulates a **51-year-old Dutch female** with a de-novo
/// diagnosis of HER2-positive, ER-negative invasief ductaal carcinoom
/// mammae links (stadiumgroep IIA, cT2N0M0).
///
/// Resources modelled:
/// * Patient (anonymous)
/// * Condition (primaire diagnose – ICD-10-NL C50.4)
/// * DiagnosticReport (pathologieverslag PA-2024-01)
/// * Observations (ER, PR, HER2, Ki-67)
/// * Procedures (schildwachtklierprocedure, BCS, radiotherapie)
/// * MedicationRequests (trastuzumab, pertuzumab, paclitaxel)
/// * CarePlan (IKNL borstkanker richtlijn 2023 referentie)
/// * Appointments (3 komende afspraken)
class MockDataService {
  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a simulated FHIR R4 Bundle for the demo oncology patient.
  /// Calling this is equivalent to a `GET /fhir/r4/Bundle/$everything` call
  /// against a Dutch EPD – but entirely local.
  Future<({FhirBundle? bundle, Failure? failure})> fetchOncologyBundle() async {
    // Simulate async I/O latency
    await Future.delayed(const Duration(milliseconds: 400));

    try {
      final resources = [
        _buildPatient(),
        _buildCondition(),
        _buildDiagnosticReport(),
        ..._buildObservations(),
        ..._buildProcedures(),
        ..._buildMedicationRequests(),
        _buildCarePlan(),
        ..._buildAppointments(),
      ];

      return (
        bundle: FhirBundle(
          resources: resources,
          timestamp: '2025-03-15T08:00:00+01:00',
        ),
        failure: null
      );
    } catch (e) {
      return (bundle: null, failure: FhirParseFailure(e.toString()));
    }
  }

  /// Returns only appointment resources (used by Appointment Navigator).
  Future<List<FhirResource>> fetchAppointments() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _buildAppointments();
  }

  /// Returns the CarePlan resource (used by Blueprint / Tijdlijn).
  Future<FhirResource> fetchCarePlan() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _buildCarePlan();
  }

  // ── FHIR resource builders ────────────────────────────────────────────────

  /// Patient resource – name fields are deliberately set to sentinel values
  /// that [IdentityShieldService] would strip in a real import flow.
  FhirResource _buildPatient() => FhirResource(
        resourceType: 'Patient',
        id: 'patient-001',
        data: {
          'resourceType': 'Patient',
          'id': 'patient-001',
          'meta': {
            'profile': [
              'http://nictiz.nl/fhir/StructureDefinition/nl-core-Patient'
            ],
          },
          'text': {
            'status': 'generated',
            'div':
                '<div xmlns="http://www.w3.org/1999/xhtml">Geanonimiseerde patiënt</div>',
          },
          // NB: name redacted by IdentityShieldService in production import
          'name': [
            {
              'use': 'official',
              'family': '[GEANONIMISEERD]',
              'given': ['[GEANONIMISEERD]'],
            }
          ],
          'gender': 'female',
          'birthDate': '[GEANONIMISEERD]', // year only in real impl
          'address': [
            {
              'use': 'home',
              'city': 'Utrecht',
              'postalCode': '[GEANONIMISEERD]',
              'country': 'NL',
            }
          ],
          'generalPractitioner': [
            {
              'reference': 'Practitioner/huisarts-001',
              'display': 'Huisartsenpraktijk Utrecht Noord',
            }
          ],
        },
      );

  /// Primary diagnosis: HER2-positief invasief ductaal carcinoom mammae links.
  FhirResource _buildCondition() => FhirResource(
        resourceType: 'Condition',
        id: 'condition-001',
        data: {
          'resourceType': 'Condition',
          'id': 'condition-001',
          'meta': {
            'profile': [
              'http://nictiz.nl/fhir/StructureDefinition/zib-Problem'
            ],
          },
          'clinicalStatus': {
            'coding': [
              {
                'system':
                    'http://terminology.hl7.org/CodeSystem/condition-clinical',
                'code': 'active',
                'display': 'Actief',
              }
            ],
          },
          'verificationStatus': {
            'coding': [
              {
                'system':
                    'http://terminology.hl7.org/CodeSystem/condition-ver-status',
                'code': 'confirmed',
                'display': 'Bevestigd',
              }
            ],
          },
          'category': [
            {
              'coding': [
                {
                  'system':
                      'http://terminology.hl7.org/CodeSystem/condition-category',
                  'code': 'encounter-diagnosis',
                  'display': 'Diagnose bij contactmoment',
                }
              ],
            }
          ],
          'severity': {
            'coding': [
              {
                'system': 'http://snomed.info/sct',
                'code': '6736007',
                'display': 'Matig ernstig',
              }
            ],
          },
          'code': {
            'coding': [
              {
                'system': 'http://hl7.org/fhir/sid/icd-10',
                'code': 'C50.4',
                'display':
                    'Maligne neoplasma van bovenste buitenste kwadrant van mamma',
              },
              {
                'system': 'http://snomed.info/sct',
                'code': '783541009',
                'display': 'Invasief ductaal carcinoom van mamma (bevinding)',
              }
            ],
            'text': 'HER2-positief invasief ductaal carcinoom mammae links',
          },
          'bodySite': [
            {
              'coding': [
                {
                  'system': 'http://snomed.info/sct',
                  'code': '368209003',
                  'display': 'Linker mamma (lichaamsstructuur)',
                }
              ],
            }
          ],
          'subject': {'reference': 'Patient/patient-001'},
          'onsetDateTime': '2024-11-20',
          'recordedDate': '2024-11-28',
          'stage': [
            {
              'summary': {
                'coding': [
                  {
                    'system': 'http://snomed.info/sct',
                    'code': '1228882005',
                    'display': 'Stadium IIA (bevinding)',
                  }
                ],
                'text': 'cT2N0M0 – Stadium IIA',
              },
              'type': {
                'coding': [
                  {
                    'system': 'http://snomed.info/sct',
                    'code': '260998006',
                    'display': 'Klinische stadiëring',
                  }
                ],
              },
            }
          ],
          'note': [
            {
              'text': 'IKNL Richtlijn Borstkanker 2023 van toepassing. '
                  'Tumorgrootte: 2,8 cm. Schildwachtklierprocedure uitgevoerd. '
                  'Geen lymfekliermetastasen vastgesteld.',
            }
          ],
        },
      );

  /// Pathology report (DiagnosticReport).
  FhirResource _buildDiagnosticReport() => FhirResource(
        resourceType: 'DiagnosticReport',
        id: 'report-pa-2024-01',
        data: {
          'resourceType': 'DiagnosticReport',
          'id': 'report-pa-2024-01',
          'status': 'final',
          'category': [
            {
              'coding': [
                {
                  'system': 'http://terminology.hl7.org/CodeSystem/v2-0074',
                  'code': 'PAT',
                  'display': 'Pathologie',
                }
              ],
            }
          ],
          'code': {
            'coding': [
              {
                'system': 'http://loinc.org',
                'code': '60568-3',
                'display': 'Pathologie-rapport',
              }
            ],
            'text': 'Pathologisch anatomisch rapport PA-2024-01',
          },
          'subject': {'reference': 'Patient/patient-001'},
          'effectiveDateTime': '2024-12-05',
          'issued': '2024-12-05T14:30:00+01:00',
          'performer': [
            {
              'reference': 'Organization/lumc-pathologie',
              'display': 'LUMC Afdeling Pathologie',
            }
          ],
          'result': [
            {'reference': 'Observation/obs-er'},
            {'reference': 'Observation/obs-pr'},
            {'reference': 'Observation/obs-her2'},
            {'reference': 'Observation/obs-ki67'},
          ],
          'conclusion':
              'HER2-positief (IHC 3+), ER-negatief, PR-negatief, Ki-67 38%. '
                  'Invasief ductaal carcinoom graad III (Bloom-Richardson).',
          'conclusionCode': [
            {
              'coding': [
                {
                  'system': 'http://snomed.info/sct',
                  'code': '783541009',
                  'display': 'Invasief ductaal carcinoom van mamma',
                }
              ],
            }
          ],
        },
      );

  /// Biomarker observations (ER, PR, HER2, Ki-67).
  List<FhirResource> _buildObservations() => [
        FhirResource(
          resourceType: 'Observation',
          id: 'obs-er',
          data: {
            'resourceType': 'Observation',
            'id': 'obs-er',
            'status': 'final',
            'category': [
              {
                'coding': [
                  {
                    'system':
                        'http://terminology.hl7.org/CodeSystem/observation-category',
                    'code': 'laboratory',
                    'display': 'Laboratorium',
                  }
                ],
              }
            ],
            'code': {
              'coding': [
                {
                  'system': 'http://loinc.org',
                  'code': '85319-2',
                  'display':
                      'Oestrogeenreceptor [aanwezigheid] in borst kanker specimen',
                }
              ],
              'text': 'Oestrogeenreceptor (ER)',
            },
            'subject': {'reference': 'Patient/patient-001'},
            'effectiveDateTime': '2024-12-05',
            'valueCodeableConcept': {
              'coding': [
                {
                  'system': 'http://snomed.info/sct',
                  'code': '260385009',
                  'display': 'Negatief',
                }
              ],
              'text': 'Negatief (0%)',
            },
            'interpretation': [
              {
                'coding': [
                  {
                    'system':
                        'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation',
                    'code': 'NEG',
                    'display': 'Negatief',
                  }
                ],
              }
            ],
          },
        ),
        FhirResource(
          resourceType: 'Observation',
          id: 'obs-pr',
          data: {
            'resourceType': 'Observation',
            'id': 'obs-pr',
            'status': 'final',
            'code': {
              'coding': [
                {
                  'system': 'http://loinc.org',
                  'code': '85325-9',
                  'display': 'Progesteronreceptor in borst kanker specimen',
                }
              ],
              'text': 'Progesteronreceptor (PR)',
            },
            'subject': {'reference': 'Patient/patient-001'},
            'effectiveDateTime': '2024-12-05',
            'valueCodeableConcept': {
              'text': 'Negatief (0%)',
            },
          },
        ),
        FhirResource(
          resourceType: 'Observation',
          id: 'obs-her2',
          data: {
            'resourceType': 'Observation',
            'id': 'obs-her2',
            'status': 'final',
            'code': {
              'coding': [
                {
                  'system': 'http://loinc.org',
                  'code': '18474-7',
                  'display':
                      'HER2 [aanwezigheid] in borst kanker specimen door immunohistochemie',
                }
              ],
              'text': 'HER2/neu (immunohistochemie)',
            },
            'subject': {'reference': 'Patient/patient-001'},
            'effectiveDateTime': '2024-12-05',
            'valueCodeableConcept': {
              'coding': [
                {
                  'system': 'http://snomed.info/sct',
                  'code': '10828004',
                  'display': 'Positief',
                }
              ],
              'text': 'Positief (IHC 3+)',
            },
            'interpretation': [
              {
                'coding': [
                  {
                    'system':
                        'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation',
                    'code': 'POS',
                    'display': 'Positief',
                  }
                ],
              }
            ],
          },
        ),
        FhirResource(
          resourceType: 'Observation',
          id: 'obs-ki67',
          data: {
            'resourceType': 'Observation',
            'id': 'obs-ki67',
            'status': 'final',
            'code': {
              'coding': [
                {
                  'system': 'http://loinc.org',
                  'code': '85326-7',
                  'display': 'Ki-67 [groei-index] in borst kanker specimen',
                }
              ],
              'text': 'Ki-67 proliferatieindex',
            },
            'subject': {'reference': 'Patient/patient-001'},
            'effectiveDateTime': '2024-12-05',
            'valueQuantity': {
              'value': 38,
              'unit': '%',
              'system': 'http://unitsofmeasure.org',
              'code': '%',
            },
            'interpretation': [
              {
                'coding': [
                  {
                    'system':
                        'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation',
                    'code': 'H',
                    'display': 'Hoog',
                  }
                ],
                'text': 'Hoog (≥25% = hoge proliferatie per IKNL)',
              }
            ],
          },
        ),
      ];

  /// Procedures: sentinel node biopsy, BCS, radiotherapy.
  List<FhirResource> _buildProcedures() => [
        FhirResource(
          resourceType: 'Procedure',
          id: 'proc-sentinel',
          data: {
            'resourceType': 'Procedure',
            'id': 'proc-sentinel',
            'status': 'completed',
            'code': {
              'coding': [
                {
                  'system': 'http://snomed.info/sct',
                  'code': '396487001',
                  'display': 'Schildwachtklierprocedure',
                }
              ],
              'text': 'Schildwachtklierprocedure (SLNB) linker axilla',
            },
            'subject': {'reference': 'Patient/patient-001'},
            'performedDateTime': '2025-01-14',
            'outcome': {
              'coding': [
                {
                  'system': 'http://snomed.info/sct',
                  'code': '385669000',
                  'display': 'Geslaagd',
                }
              ],
              'text': 'Geen lymfekliermetastasen (pN0 SN)',
            },
            'note': [
              {'text': 'IKNL aanbeveling: SLNB bij cN0 borstkanker.'}
            ],
          },
        ),
        FhirResource(
          resourceType: 'Procedure',
          id: 'proc-bcs',
          data: {
            'resourceType': 'Procedure',
            'id': 'proc-bcs',
            'status': 'completed',
            'code': {
              'coding': [
                {
                  'system': 'http://snomed.info/sct',
                  'code': '392021009',
                  'display': 'Borstsparende chirurgie',
                }
              ],
              'text': 'Borstsparende chirurgie (BCS) – lumpectomie',
            },
            'subject': {'reference': 'Patient/patient-001'},
            'performedDateTime': '2025-01-14',
            'performer': [
              {
                'actor': {
                  'reference': 'Practitioner/onco-chirurg-001',
                  'display': 'Onco-chirurg, UMC Utrecht',
                }
              }
            ],
            'note': [
              {
                'text': 'Vrije resectiemarges geconfirmeerd. R0-resectie. '
                    'IKNL richtlijn: adjuvante radiotherapie geïndiceerd na BCS.'
              }
            ],
          },
        ),
        FhirResource(
          resourceType: 'Procedure',
          id: 'proc-radio',
          data: {
            'resourceType': 'Procedure',
            'id': 'proc-radio',
            'status': 'in-progress',
            'code': {
              'coding': [
                {
                  'system': 'http://snomed.info/sct',
                  'code': '108290001',
                  'display': 'Radiotherapie',
                }
              ],
              'text': 'Adjuvante radiotherapie linker mamma (15 fracties)',
            },
            'subject': {'reference': 'Patient/patient-001'},
            'performedPeriod': {
              'start': '2025-03-01',
              'end': '2025-03-21',
            },
            'reasonReference': [
              {'reference': 'Condition/condition-001'}
            ],
            'note': [
              {
                'text':
                    'Hypofractionering 40 Gy / 15 fracties per FAST-Forward protocol. '
                        'IKNL Richtlijn Borstkanker 2023 §6.3.'
              }
            ],
          },
        ),
      ];

  /// Systemic therapy: neoadjuvant trastuzumab + pertuzumab + paclitaxel.
  List<FhirResource> _buildMedicationRequests() => [
        FhirResource(
          resourceType: 'MedicationRequest',
          id: 'medrq-tras',
          data: {
            'resourceType': 'MedicationRequest',
            'id': 'medrq-tras',
            'status': 'active',
            'intent': 'order',
            'medicationCodeableConcept': {
              'coding': [
                {
                  'system': 'http://www.whocc.no/atc',
                  'code': 'L01XC03',
                  'display': 'Trastuzumab',
                }
              ],
              'text': 'Trastuzumab (Herceptin) 6 mg/kg IV q3w',
            },
            'subject': {'reference': 'Patient/patient-001'},
            'authoredOn': '2024-12-20',
            'reasonReference': [
              {'reference': 'Condition/condition-001'}
            ],
            'dosageInstruction': [
              {
                'text': '6 mg/kg intraveneus elke 3 weken, 18 cycli totaal',
                'route': {
                  'coding': [
                    {
                      'system': 'http://snomed.info/sct',
                      'code': '47625008',
                      'display': 'Intraveneuze route',
                    }
                  ],
                },
              }
            ],
            'note': [
              {
                'text':
                    'IKNL: Trastuzumab + pertuzumab gedurende 1 jaar bij HER2-positief '
                        'stadium I-III. Echocardiografie q3m ter controle LVEF.',
              }
            ],
          },
        ),
        FhirResource(
          resourceType: 'MedicationRequest',
          id: 'medrq-pertu',
          data: {
            'resourceType': 'MedicationRequest',
            'id': 'medrq-pertu',
            'status': 'active',
            'intent': 'order',
            'medicationCodeableConcept': {
              'coding': [
                {
                  'system': 'http://www.whocc.no/atc',
                  'code': 'L01XC13',
                  'display': 'Pertuzumab',
                }
              ],
              'text': 'Pertuzumab (Perjeta) 420 mg IV q3w',
            },
            'subject': {'reference': 'Patient/patient-001'},
            'authoredOn': '2024-12-20',
          },
        ),
        FhirResource(
          resourceType: 'MedicationRequest',
          id: 'medrq-pacli',
          data: {
            'resourceType': 'MedicationRequest',
            'id': 'medrq-pacli',
            'status': 'completed',
            'intent': 'order',
            'medicationCodeableConcept': {
              'coding': [
                {
                  'system': 'http://www.whocc.no/atc',
                  'code': 'L01CD01',
                  'display': 'Paclitaxel',
                }
              ],
              'text': 'Paclitaxel 80 mg/m² IV wekelijks (neoadjuvant)',
            },
            'subject': {'reference': 'Patient/patient-001'},
            'authoredOn': '2024-12-20',
            'note': [
              {
                'text':
                    'Neoadjuvant schema TCHP (taxaan + carboplatine + HER2-blokkade). '
                        'Afgerond na 6 cycli. pCR bereikt in axilla.',
              }
            ],
          },
        ),
      ];

  /// CarePlan based on IKNL Richtlijn Borstkanker 2023.
  FhirResource _buildCarePlan() => FhirResource(
        resourceType: 'CarePlan',
        id: 'careplan-001',
        data: {
          'resourceType': 'CarePlan',
          'id': 'careplan-001',
          'status': 'active',
          'intent': 'plan',
          'title': 'Oncologisch zorgplan – IKNL Richtlijn Borstkanker 2023',
          'description':
              'Persoonlijk zorgplan op basis van HER2-positief invasief ductaal '
                  'carcinoom stadium IIA. Gebaseerd op IKNL-richtlijn 2023.',
          'subject': {'reference': 'Patient/patient-001'},
          'period': {
            'start': '2024-12-01',
            'end': '2026-12-01',
          },
          'activity': [
            {
              'detail': {
                'kind': 'ServiceRequest',
                'code': {
                  'text': 'Neoadjuvante chemotherapie (TCHP schema) – VOLTOOID',
                },
                'status': 'completed',
                'scheduledPeriod': {
                  'start': '2024-12-20',
                  'end': '2025-01-10',
                },
                'description':
                    'IKNL: Neoadjuvante HER2-gerichte therapie aanbevolen bij '
                        'cT2 HER2-positieve tumoren.',
              },
            },
            {
              'detail': {
                'kind': 'ServiceRequest',
                'code': {
                  'text':
                      'Borstsparende chirurgie + schildwachtklierprocedure – VOLTOOID',
                },
                'status': 'completed',
                'scheduledPeriod': {
                  'start': '2025-01-14',
                  'end': '2025-01-14',
                },
              },
            },
            {
              'detail': {
                'kind': 'ServiceRequest',
                'code': {'text': 'Adjuvante radiotherapie – ACTIEF'},
                'status': 'in-progress',
                'scheduledPeriod': {
                  'start': '2025-03-01',
                  'end': '2025-03-21',
                },
                'description':
                    'IKNL §6.3: Hypofractionering (40 Gy / 15 fracties) na BCS.',
              },
            },
            {
              'detail': {
                'kind': 'MedicationRequest',
                'code': {
                  'text': 'Adjuvant trastuzumab + pertuzumab (1 jaar) – ACTIEF',
                },
                'status': 'in-progress',
                'scheduledPeriod': {
                  'start': '2025-01-20',
                  'end': '2026-01-20',
                },
                'description':
                    'IKNL: 18 cycli trastuzumab + pertuzumab. LVEF-monitoring q3m.',
              },
            },
            {
              'detail': {
                'kind': 'ServiceRequest',
                'code': {
                  'text': 'Jaarlijkse mammografie controle-plan – GEPLAND',
                },
                'status': 'scheduled',
                'scheduledPeriod': {
                  'start': '2026-06-01',
                  'end': '2031-06-01',
                },
                'description':
                    'IKNL: Jaarlijkse mammografie gedurende 5 jaar na behandeling. '
                        'Echocardiografie LVEF q6m t/m einde trastuzumab.',
              },
            },
          ],
          'note': [
            {
              'text': 'Richtlijn: https://www.iknl.nl/richtlijnen/borstkanker. '
                  'MDO-besluit: 2024-12-12 Multidisciplinair Overleg UMC Utrecht.',
            }
          ],
        },
      );

  /// Upcoming appointments for the Appointment Navigator.
  List<FhirResource> _buildAppointments() => [
        FhirResource(
          resourceType: 'Appointment',
          id: 'appt-001',
          data: {
            'resourceType': 'Appointment',
            'id': 'appt-001',
            'status': 'booked',
            'serviceCategory': [
              {
                'coding': [
                  {
                    'system': 'http://snomed.info/sct',
                    'code': '363346000',
                    'display': 'Oncologie',
                  }
                ],
                'text': 'Oncologie',
              }
            ],
            'serviceType': [
              {
                'text': 'Poliklinisch consult medisch oncoloog',
              }
            ],
            'reasonCode': [
              {
                'text':
                    'Tussentijdse evaluatie radiotherapie + trastuzumab bijwerkingen',
              }
            ],
            'start': '2025-04-08T10:30:00+02:00',
            'end': '2025-04-08T11:00:00+02:00',
            'participant': [
              {
                'actor': {
                  'reference': 'Practitioner/oncoloog-001',
                  'display': 'Dr. A. de Vries – Medisch oncoloog',
                },
                'status': 'accepted',
              },
              {
                'actor': {'reference': 'Patient/patient-001'},
                'status': 'accepted',
              }
            ],
            'location': {
              'reference': 'Location/umcu-oncologie',
              'display': 'UMC Utrecht – Afdeling Oncologie, Polikliniek 3B',
            },
            'comment':
                'Meenemen: bijwerkingendagboek, lijst met huidige medicatie, '
                    'vragen over LVEF-uitslag echocardiografie.',
          },
        ),
        FhirResource(
          resourceType: 'Appointment',
          id: 'appt-002',
          data: {
            'resourceType': 'Appointment',
            'id': 'appt-002',
            'status': 'booked',
            'serviceType': [
              {'text': 'Echocardiografie – LVEF-meting'},
            ],
            'reasonCode': [
              {
                'text':
                    'LVEF-monitoring trastuzumab: cardiotoxiciteitscontrole q3m',
              }
            ],
            'start': '2025-04-22T09:00:00+02:00',
            'end': '2025-04-22T09:30:00+02:00',
            'participant': [
              {
                'actor': {
                  'reference': 'Practitioner/cardioloog-001',
                  'display': 'Afdeling Cardiologie',
                },
                'status': 'accepted',
              }
            ],
            'location': {
              'display': 'UMC Utrecht – Afdeling Cardiologie',
            },
          },
        ),
        FhirResource(
          resourceType: 'Appointment',
          id: 'appt-003',
          data: {
            'resourceType': 'Appointment',
            'id': 'appt-003',
            'status': 'booked',
            'serviceType': [
              {'text': 'Nacontrole radiotherapie'},
            ],
            'reasonCode': [
              {'text': 'Afsluiting radiotherapie – beoordeling huidreactie'},
            ],
            'start': '2025-04-25T14:00:00+02:00',
            'end': '2025-04-25T14:30:00+02:00',
            'participant': [
              {
                'actor': {
                  'reference': 'Practitioner/radiotherapeut-001',
                  'display': 'Dr. M. Peters – Radiotherapeut-oncoloog',
                },
                'status': 'accepted',
              }
            ],
            'location': {
              'display': 'UMC Utrecht – Afdeling Radiotherapie',
            },
          },
        ),
      ];
}
