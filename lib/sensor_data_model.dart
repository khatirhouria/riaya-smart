import 'dart:math';

/// Modèle de données pour tous les capteurs ESP32-S3
class SensorData {
  final String incubatorId;
  final DateTime timestamp;

  // DHT22 — Environnement couveuse
  final double incubatorTemperature; // °C
  final double incubatorHumidity;    // %

  // DS18B20 / capteur cutané — Température corps bébé
  final double babyBodyTemperature;  // °C

  // MPU6050 — Mouvement bébé
  final double accelerometerX;
  final double accelerometerY;
  final double accelerometerZ;
  final bool babyMovementDetected;

  // HX711 — Poids bébé
  final double babyWeight;           // grammes

  // MAX30102 — Fréquence cardiaque + SpO2
  final int heartRate;               // bpm
  final double spo2;                 // %

  // MQ5 — Détecteur de gaz
  final double gasLevel;             // ppm
  final bool gasAlert;

  // TLPCF8591T — Capteur de lumière
  final double lightLevel;           // lux (0-255 ADC converti)

  // ESP32-CAM — Streaming
  final String? streamUrl;

  const SensorData({
    required this.incubatorId,
    required this.timestamp,
    required this.incubatorTemperature,
    required this.incubatorHumidity,
    required this.babyBodyTemperature,
    required this.accelerometerX,
    required this.accelerometerY,
    required this.accelerometerZ,
    required this.babyMovementDetected,
    required this.babyWeight,
    required this.heartRate,
    required this.spo2,
    required this.gasLevel,
    required this.gasAlert,
    required this.lightLevel,
    this.streamUrl,
  });

  // ─────────────────────────────────────────────────────────────────────────
  // DONNÉES SIMULÉES — valeurs réalistes et uniques par couveuse
  // ─────────────────────────────────────────────────────────────────────────
  factory SensorData.mock(String id) {
    final rng = Random();
    final int ms  = DateTime.now().millisecond;
    final int sec = DateTime.now().second;

    switch (id) {

    // ── INC-001 : Yasmine Benali — 28 SA — paramètres stables ───────────
      case 'INC-001':
        return SensorData(
          incubatorId:          id,
          timestamp:            DateTime.now(),
          incubatorTemperature: 36.8 + (ms % 10) * 0.02,          // 36.8–37.0 °C
          incubatorHumidity:    62.0 + (ms % 8)  * 0.10,          // 62–62.8 %
          babyBodyTemperature:  36.9 + (ms % 4)  * 0.05,          // 36.9–37.1 °C
          accelerometerX:       0.12 + (ms % 5)  * 0.01,
          accelerometerY:      -0.05 + (ms % 3)  * 0.01,
          accelerometerZ:       9.79 + (ms % 4)  * 0.01,
          babyMovementDetected: sec % 7 < 2,                       // calme
          babyWeight:           1018.0 + (sec % 5),                // ~1020 g
          heartRate:            148 + sec % 10,                    // 148–158 bpm ✓
          spo2:                 96.5 + (ms % 5)  * 0.10,           // 96.5–97.0 % ✓
          gasLevel:             12.4 + (ms % 6)  * 0.10,           // 12–13 ppm ✓
          gasAlert:             false,
          lightLevel:           38.0 + (sec % 5),                  // 38–43 lux
          streamUrl:            'http://192.168.1.103:81/stream',
        );

    // ── INC-002 : Adam Khelifi — 31 SA — FC légèrement élevée ───────────
      case 'INC-002':
        final int hr = 168 + sec % 14;                             // 168–182 bpm (limite haute)
        return SensorData(
          incubatorId:          id,
          timestamp:            DateTime.now(),
          incubatorTemperature: 37.2 + (ms % 6)  * 0.02,          // 37.2–37.3 °C ✓
          incubatorHumidity:    51.0 + (ms % 5)  * 0.10,          // 51–51.5 % (basse)
          babyBodyTemperature:  37.1 + (ms % 3)  * 0.05,          // 37.1–37.2 °C ✓
          accelerometerX:       0.31 + (ms % 4)  * 0.02,
          accelerometerY:       0.18 + (ms % 3)  * 0.01,
          accelerometerZ:       9.81 + (ms % 3)  * 0.01,
          babyMovementDetected: sec % 5 < 3,                       // agité
          babyWeight:           1375.0 + (sec % 8),                // ~1380 g
          heartRate:            hr,                                 // ⚠ peut dépasser 180
          spo2:                 95.2 + (ms % 3)  * 0.10,           // 95.2–95.5 % ✓
          gasLevel:             8.7  + (ms % 4)  * 0.10,           // 8–9 ppm ✓
          gasAlert:             false,
          lightLevel:           22.0 + (sec % 6),                  // 22–28 lux
          streamUrl:            'http://192.168.1.103:81/stream',
        );

    // ── INC-003 : Lina Hadj — 26 SA — grande prématurée, SpO2 limite ────
      case 'INC-003':
      default:
        final bool gasSpike = sec % 20 < 5;                        // pic gaz toutes les 20 s
        return SensorData(
          incubatorId:          id,
          timestamp:            DateTime.now(),
          incubatorTemperature: 36.4 + (ms % 7)  * 0.02,          // 36.4–36.5 °C ✓
          incubatorHumidity:    67.0 + (ms % 6)  * 0.10,          // 67–67.6 % ✓
          babyBodyTemperature:  36.6 + (ms % 3)  * 0.05,          // 36.6–36.7 °C ✓
          accelerometerX:       0.05 + (ms % 3)  * 0.01,
          accelerometerY:      -0.02 + (ms % 2)  * 0.01,
          accelerometerZ:       9.80 + (ms % 2)  * 0.01,
          babyMovementDetected: sec % 10 < 2,                      // très calme
          babyWeight:           775.0 + (sec % 4),                 // ~778 g
          heartRate:            138 + sec % 8,                     // 138–146 bpm ✓
          spo2:                 93.1 + (ms % 4)  * 0.10,           // ⚠ < 94 % (alerte)
          gasLevel:             gasSpike ? 34.8 + rng.nextDouble() * 2 : 18.2 + (ms % 5) * 0.10,
          gasAlert:             gasSpike,                          // ⚠ pic périodique
          lightLevel:           15.0 + (sec % 4),                  // 15–19 lux (ambiance sombre)
          streamUrl:            'http://192.168.1.103:81/stream',
        );
    }
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      incubatorId:          json['incubator_id'] ?? '',
      timestamp:            DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      incubatorTemperature: (json['incubator_temp']     ?? 0.0).toDouble(),
      incubatorHumidity:    (json['incubator_humidity'] ?? 0.0).toDouble(),
      babyBodyTemperature:  (json['baby_body_temp']     ?? 0.0).toDouble(),
      accelerometerX:       (json['accel_x']            ?? 0.0).toDouble(),
      accelerometerY:       (json['accel_y']            ?? 0.0).toDouble(),
      accelerometerZ:       (json['accel_z']            ?? 0.0).toDouble(),
      babyMovementDetected: json['movement']   ?? false,
      babyWeight:           (json['weight_g']  ?? 0.0).toDouble(),
      heartRate:            json['heart_rate'] ?? 0,
      spo2:                 (json['spo2']      ?? 0.0).toDouble(),
      gasLevel:             (json['gas_ppm']   ?? 0.0).toDouble(),
      gasAlert:             json['gas_alert']  ?? false,
      lightLevel:           (json['light_lux'] ?? 0.0).toDouble(),
      streamUrl:            json['stream_url'],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILS BÉBÉS — 3 bébés distincts, un par couveuse
// ─────────────────────────────────────────────────────────────────────────────
class BabyProfile {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final double birthWeight;
  final int gestationalAge;   // semaines
  final String incubatorId;
  final String parentContact;
  final String doctorName;

  const BabyProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.birthWeight,
    required this.gestationalAge,
    required this.incubatorId,
    required this.parentContact,
    required this.doctorName,
  });

  /// Retourne le profil fixe correspondant à la couveuse.
  /// Chaque couveuse a toujours le même bébé — plus de données aléatoires.
  factory BabyProfile.forIncubator(String incubatorId) {
    switch (incubatorId) {

    // ── INC-001 : Yasmine Benali ─────────────────────────────────────────
      case 'INC-001':
        return BabyProfile(
          id:             'B001',
          firstName:      'Yasmine',
          lastName:       'Benali',
          birthDate:      DateTime(2025, 3, 15),  // 12 jours de vie
          birthWeight:    980.0,
          gestationalAge: 28,
          incubatorId:    'INC-001',
          parentContact:  '+213 555 111 222',
          doctorName:     'Dr. Karim Meziane',
        );

    // ── INC-002 : Adam Khelifi ───────────────────────────────────────────
      case 'INC-002':
        return BabyProfile(
          id:             'B002',
          firstName:      'Adam',
          lastName:       'Khelifi',
          birthDate:      DateTime(2025, 3, 22),  // 5 jours de vie
          birthWeight:    1340.0,
          gestationalAge: 31,
          incubatorId:    'INC-002',
          parentContact:  '+213 555 333 444',
          doctorName:     'Dr. Nadia Bouazza',
        );

    // ── INC-003 : Lina Hadj ──────────────────────────────────────────────
      case 'INC-003':
      default:
        return BabyProfile(
          id:             'B003',
          firstName:      'Lina',
          lastName:       'Hadj',
          birthDate:      DateTime(2025, 3, 7),   // 20 jours de vie
          birthWeight:    740.0,
          gestationalAge: 26,
          incubatorId:    'INC-003',
          parentContact:  '+213 555 555 666',
          doctorName:     'Dr. Karim Meziane',
        );
    }
  }

  /// Conservé pour compatibilité — pointe vers INC-001 par défaut.
  factory BabyProfile.mock() => BabyProfile.forIncubator('INC-001');
}

// ─────────────────────────────────────────────────────────────────────────────
// UTILISATEUR MÉDICAL
// ─────────────────────────────────────────────────────────────────────────────
class MedicalUser {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String role;      // 'Médecin' | 'Infirmier(ère)'
  final String service;
  final String hospital;

  const MedicalUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.service,
    required this.hospital,
  });

  factory MedicalUser.mock(String role) {
    return MedicalUser(
      id:       'U001',
      fullName: role == 'Médecin' ? 'Dr. Amira Hadj' : 'Inf. Yasmine Bouzidi',
      email:    'amira.hadj@chu-tlemcen.dz',
      phone:    '+213 555 987 654',
      role:     role,
      service:  'Néonatologie',
      hospital: 'CHU Tlemcen',
    );
  }
}