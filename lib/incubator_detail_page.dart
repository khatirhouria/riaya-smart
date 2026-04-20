import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'app_theme.dart';
import 'sensor_data_model.dart';
import 'sensor_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TYPE D'UTILISATEUR
// ─────────────────────────────────────────────────────────────────────────────
enum UserRole { medical, technician }

class IncubatorDetailPage extends StatefulWidget {
  final String incubatorId;
  final BabyProfile baby;
  final SensorData initialData;

  /// Rôle de l'utilisateur connecté.
  /// medical   → médecin / infirmière  (vue simplifiée, sans noms techniques)
  /// technician → technicien / admin   (vue complète avec noms de capteurs)
  final UserRole userRole;

  const IncubatorDetailPage({
    super.key,
    required this.incubatorId,
    required this.baby,
    required this.initialData,
    this.userRole = UserRole.medical, // par défaut : vue médicale
  });

  @override
  State<IncubatorDetailPage> createState() => _IncubatorDetailPageState();
}

class _IncubatorDetailPageState extends State<IncubatorDetailPage>
    with SingleTickerProviderStateMixin {
  late SensorData _data;
  late TabController _tabController;
  Timer? _refreshTimer;

  bool get _isMedical => widget.userRole == UserRole.medical;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData;
    _tabController = TabController(length: 3, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() => _data = SensorData.mock(widget.incubatorId));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _buildAppBar(),
          _buildBabyInfoBar(),
          _buildTabBar(),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _EnvironmentTab(data: _data, isMedical: _isMedical),
            _VitalSignsTab(data: _data, isMedical: _isMedical),
            _CameraTab(
              streamUrl: _data.streamUrl,
              incubatorId: widget.incubatorId,
              isMedical: _isMedical,
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.incubatorId, style: const TextStyle(
            fontFamily: 'Nunito', fontWeight: FontWeight.w900,
            color: Colors.white, fontSize: 18,
          )),
          Text('${widget.baby.firstName} ${widget.baby.lastName}',
              style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 12, color: Colors.white70,
              )),
        ],
      ),
      actions: [
        const LiveIndicator(),
        const SizedBox(width: 12),
      ],
    );
  }

  SliverToBoxAdapter _buildBabyInfoBar() {
    final age = DateTime.now().difference(widget.baby.birthDate).inDays;
    return SliverToBoxAdapter(
      child: Container(
        color: AppColors.primaryDark,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoChip(label: 'Âge', value: '$age j'),
              _vDivider(),
              _InfoChip(label: 'Sem. gest.', value: '${widget.baby.gestationalAge} sem'),
              _vDivider(),
              _InfoChip(label: 'Poids naiss.', value: '${widget.baby.birthWeight.toInt()}g'),
              _vDivider(),
              _InfoChip(label: 'Médecin', value: widget.baby.doctorName.replaceAll('Dr. ', 'Dr.')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1, height: 30,
    color: Colors.white.withOpacity(0.2),
  );

  SliverPersistentHeader _buildTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          labelStyle: const TextStyle(
            fontFamily: 'Nunito', fontWeight: FontWeight.w700, fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Environnement'),
            Tab(text: 'Signes vitaux'),
            Tab(text: 'Caméra'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET ENVIRONNEMENT
// ─────────────────────────────────────────────────────────────────────────────
class _EnvironmentTab extends StatelessWidget {
  final SensorData data;
  final bool isMedical;
  const _EnvironmentTab({required this.data, required this.isMedical});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Environnement couveuse ──────────────────────────────────────────
        SectionHeader(
          title: 'Environnement couveuse',
          icon: Icons.device_thermostat_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SensorCard(
                title: 'Température',
                value: data.incubatorTemperature.toStringAsFixed(1),
                unit: '°C',
                icon: Icons.thermostat_rounded,
                color: AppColors.tempColor,
                isAlert: data.incubatorTemperature < 36 || data.incubatorTemperature > 38,
                subtitle: 'Température de la couveuse',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SensorCard(
                title: 'Humidité',
                value: data.incubatorHumidity.toStringAsFixed(1),
                unit: '%',
                icon: Icons.water_drop_outlined,
                color: AppColors.humidityColor,
                isAlert: data.incubatorHumidity < 50 || data.incubatorHumidity > 70,
                subtitle: 'Humidité relative de la couveuse',
              ),
            ),
          ],
        ),



        // ── Mouvement ──────────────────────────────────────────────────────
        const SizedBox(height: 20),
        SectionHeader(title: 'Activité du bébé', icon: Icons.vibration_rounded),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatusCard(
                title: 'Mouvement',
                active: data.babyMovementDetected,
                icon: Icons.vibration_rounded,
                color: AppColors.movColor,
                activeLabel: 'Mouvement détecté',
                inactiveLabel: 'Calme',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.accentSoft, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Médecin : "Accélération corporelle", technicien : "Accéléromètre"
                    Text(
                      isMedical ? 'Accélération corporelle' : 'Accéléromètre',
                      style: AppTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 8),
                    _AccelRow('X', data.accelerometerX),
                    _AccelRow('Y', data.accelerometerY),
                    _AccelRow('Z', data.accelerometerZ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ── Qualité de l'air ───────────────────────────────────────────────
        const SizedBox(height: 20),
        SectionHeader(
          // Médecin : libellé clinique, technicien : nom du capteur
          title: isMedical ? "Qualité de l'air" : 'Détecteur de gaz',
          icon: Icons.air_rounded,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SensorCard(
                title: isMedical ? 'Concentration de gaz' : 'Niveau de gaz',
                value: data.gasLevel.toStringAsFixed(1),
                unit: 'ppm',
                icon: Icons.sensors_rounded,
                color: AppColors.gasColor,
                isAlert: data.gasAlert,
                subtitle: 'Détection de gaz dans la couveuse',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatusCard(
                title: 'Alerte air',
                active: data.gasAlert,
                icon: Icons.warning_amber_rounded,
                color: AppColors.gasColor,
                activeLabel: 'DANGER !',
                inactiveLabel: 'Air sain',
              ),
            ),
          ],
        ),



        // ── Carte connexion (technicien uniquement) ─────────────────────────
        const SizedBox(height: 20),
        if (!isMedical) ...[
          _Esp32InfoCard(),
          const SizedBox(height: 8),
        ],

        // ── Statut matériel simplifié (médecin) ────────────────────────────
        if (isMedical) ...[
          _DeviceStatusCard(),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET SIGNES VITAUX
// ─────────────────────────────────────────────────────────────────────────────
class _VitalSignsTab extends StatelessWidget {
  final SensorData data;
  final bool isMedical;
  const _VitalSignsTab({required this.data, required this.isMedical});

  bool get _hrAlert => data.heartRate > 180 || data.heartRate < 100;
  bool get _tempAlert => data.babyBodyTemperature < 36.0 || data.babyBodyTemperature > 37.5;
  bool get _spo2Alert => data.spo2 < 94;

  Widget _normRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text('$label : ', style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 11,
          fontWeight: FontWeight.w700, color: AppColors.textSecondary,
        )),
        Expanded(child: Text(value, style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 11, color: AppColors.textPrimary,
        ))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionHeader(
          // Médecin : libellé clinique, technicien : modèle du capteur
          title: isMedical
              ? 'Fréquence cardiaque & Saturation O₂'
              : 'MAX30102 – Fréquence cardiaque & SpO2',
          icon: Icons.favorite_rounded,
        ),
        const SizedBox(height: 12),
        _HeartRateCard(heartRate: data.heartRate, isAlert: _hrAlert),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SensorCard(
                title: 'Saturation en oxygène',
                value: data.spo2.toStringAsFixed(1),
                unit: '%',
                icon: Icons.bloodtype_outlined,
                color: AppColors.spo2Color,
                isAlert: _spo2Alert,
                // Médecin : pas d'acronyme technique
                subtitle: isMedical ? 'Saturation en oxygène du bébé' : 'SpO2 – Capteur MAX30102',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Paramètres vitaux',
                        style: TextStyle(
                          fontFamily: 'Nunito', fontSize: 12,
                          fontWeight: FontWeight.w800, color: AppColors.primary,
                        )),
                    const SizedBox(height: 10),
                    _normRow('FC', '${_hrAlert ? "⚠" : "✓"} Fréq. card.'),
                    _normRow('SpO₂', '${_spo2Alert ? "⚠" : "✓"} Saturation'),
                    _normRow('Temp', '${_tempAlert ? "⚠" : "✓"} Corporelle'),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SectionHeader(
          title: 'Température corporelle',
          icon: Icons.thermostat_rounded,
        ),
        const SizedBox(height: 12),
        SensorCard(
          title: 'Temp. corporelle',
          value: data.babyBodyTemperature.toStringAsFixed(1),
          unit: '°C',
          icon: Icons.child_care_rounded,
          color: AppColors.tempColor,
          isAlert: _tempAlert,
          subtitle: 'Température corporelle du bébé',
        ),
        const SizedBox(height: 20),

// ── Poids ──────────────────────────────────────────────────────────
        SectionHeader(
          title: 'Poids du bébé',
          icon: Icons.monitor_weight_outlined,
        ),
        const SizedBox(height: 12),

        SensorCard(
          title: 'Poids actuel',
          value: data.babyWeight.toStringAsFixed(0),
          unit: 'g',
          icon: Icons.monitor_weight_outlined,
          color: AppColors.weightColor,
          subtitle: 'Mise à jour toutes les 5 s',
        ),
        const SizedBox(height: 20),
        _GlobalStatusCard(
          hrAlert: _hrAlert,
          tempAlert: _tempAlert,
          spo2Alert: _spo2Alert,
          gasAlert: data.gasAlert,
        ),

      ],
    );

  }

}

// ─────────────────────────────────────────────────────────────────────────────
// ONGLET CAMÉRA
// ─────────────────────────────────────────────────────────────────────────────
class _CameraTab extends StatefulWidget {
  final String? streamUrl;
  final String incubatorId;
  final bool isMedical;

  const _CameraTab({
    this.streamUrl,
    required this.incubatorId,
    required this.isMedical,
  });

  @override
  State<_CameraTab> createState() => _CameraTabState();
}

class _CameraTabState extends State<_CameraTab> {
  static const String _camBaseUrl = 'http://192.168.0.111:81';
  static const String _streamPath = '/stream';
  static const String _capturePath = '/capture';

  bool _isFullscreen = false;
  Key _mjpegKey = UniqueKey();

  void _reconnect() => setState(() => _mjpegKey = UniqueKey());

  void _capturePhoto() async {
    try {
      final uri = Uri.parse('$_camBaseUrl$_capturePath');
      await HttpClient().getUrl(uri);
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text('Photo capturée !',
                style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double streamHeight =
    _isFullscreen ? MediaQuery.of(context).size.height * 0.72 : 260;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Lecteur vidéo ──────────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: streamHeight,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.success.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Mjpeg(
                    key: _mjpegKey,
                    stream: '$_camBaseUrl$_streamPath',
                    isLive: true,
                    fit: BoxFit.contain,
                    loading: (context) => Container(
                      color: Colors.black,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2.5,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Connexion à la caméra…',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    error: (context, error, stack) => Container(
                      color: Colors.black87,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off_rounded,
                                color: AppColors.error.withOpacity(0.8), size: 52),
                            const SizedBox(height: 12),
                            const Text(
                              'Caméra indisponible',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Vérifiez la connexion réseau',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: _reconnect,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.primary.withOpacity(0.5)),
                                ),
                                child: const Text(
                                  'Réessayer',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Badge EN DIRECT
                const Positioned(top: 10, left: 10, child: LiveIndicator()),

                // Badge URL (technicien uniquement)
                if (!widget.isMedical)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_camBaseUrl$_streamPath',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Bouton plein écran
                Positioned(
                  top: 6,
                  right: 6,
                  child: Material(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => _isFullscreen = !_isFullscreen),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white70,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ── Boutons d'action ───────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _CameraButton(
                icon: Icons.refresh_rounded,
                label: 'Reconnecter',
                onTap: _reconnect,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CameraButton(
                icon: Icons.camera_alt_rounded,
                label: 'Capturer photo',
                onTap: _capturePhoto,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Bloc d'info caméra ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                // Médecin : pas de référence matérielle
                title: widget.isMedical
                    ? 'Informations de la caméra'
                    : 'ESP32-CAM – Informations techniques',
                icon: Icons.camera_rounded,
              ),
              const SizedBox(height: 12),
              if (widget.isMedical) ...[
                // Vue médicale : infos utiles uniquement
                _infoRow('Couveuse', widget.incubatorId),
                _infoRow('Résolution', 'Haute définition'),
                _infoRow('Fréquence', '~15 images/seconde'),
                _infoRow('Statut', 'En direct'),
              ] else ...[
                // Vue technicien : tous les détails
                _infoRow('Modèle', 'ESP32-CAM AI-Thinker'),
                _infoRow('Résolution', '1600×1200 (UXGA)'),
                _infoRow('Format', 'MJPEG Stream'),
                _infoRow('URL Stream', '$_camBaseUrl$_streamPath'),
                _infoRow('URL Capture', '$_camBaseUrl$_capturePath'),
                _infoRow('FPS', '~15 fps (WiFi)'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label : ', style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 13,
          fontWeight: FontWeight.w600, color: AppColors.textSecondary,
        )),
        Expanded(
          child: Text(value, style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 13, color: AppColors.textPrimary,
          )),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE STATUT SIMPLIFIÉ (vue médicale uniquement)
// ─────────────────────────────────────────────────────────────────────────────
class _DeviceStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withOpacity(0.25)),
      ),
      child: Row(
        children: const [
          Icon(Icons.wifi_rounded, color: AppColors.success, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Couveuse connectée et opérationnelle',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE CONNEXION ESP32 (vue technicien uniquement)
// ─────────────────────────────────────────────────────────────────────────────
class _Esp32InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.memory_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('ESP32-S3 N16B8 – Statut connexion',
                  style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 14,
                    fontWeight: FontWeight.w800, color: AppColors.textPrimary,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          _statusRow('WiFi', '192.168.0.111', true),
          _statusRow('MQTT Broker', 'mqtt://riaya.local', true),
          _statusRow('Uptime', '2 h 34 min', true),
          _statusRow('Dernière synchro', 'il y a 3 s', true),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel,
              color: ok ? AppColors.success : AppColors.error, size: 14),
          const SizedBox(width: 6),
          Text('$label : ', style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 12,
            fontWeight: FontWeight.w600, color: AppColors.textSecondary,
          )),
          Text(value, style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 12, color: AppColors.textPrimary,
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS PARTAGÉS
// ─────────────────────────────────────────────────────────────────────────────
class _AccelRow extends StatelessWidget {
  final String axis;
  final double value;
  const _AccelRow(this.axis, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$axis : ', style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 12,
            fontWeight: FontWeight.w700, color: AppColors.textSecondary,
          )),
          Text(value.toStringAsFixed(2), style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 12, color: AppColors.textPrimary,
          )),
          const Text(' m/s²', style: TextStyle(
            fontFamily: 'Nunito', fontSize: 10, color: AppColors.textHint,
          )),
        ],
      ),
    );
  }
}

class _HeartRateCard extends StatefulWidget {
  final int heartRate;
  final bool isAlert;
  const _HeartRateCard({required this.heartRate, required this.isAlert});

  @override
  State<_HeartRateCard> createState() => _HeartRateCardState();
}

class _HeartRateCardState extends State<_HeartRateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    final ms = (60000 / widget.heartRate).round();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.isAlert
              ? [AppColors.error.withOpacity(0.1), AppColors.error.withOpacity(0.05)]
              : [AppColors.heartColor.withOpacity(0.08), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isAlert
              ? AppColors.error.withOpacity(0.5)
              : AppColors.heartColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulse,
            child: Icon(
              Icons.favorite_rounded,
              color: widget.isAlert ? AppColors.error : AppColors.heartColor,
              size: 52,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fréquence cardiaque', style: AppTextStyles.cardTitle),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.heartRate}',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: widget.isAlert ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8, left: 4),
                    child: Text('BPM', style: AppTextStyles.cardUnit),
                  ),
                ],
              ),
              Text(
                widget.isAlert ? 'Attention requise' : 'Stable',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: widget.isAlert ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}




class _GlobalStatusCard extends StatelessWidget {
  final bool hrAlert;
  final bool tempAlert;
  final bool spo2Alert;
  final bool gasAlert;

  const _GlobalStatusCard({
    required this.hrAlert, required this.tempAlert,
    required this.spo2Alert, required this.gasAlert,
  });

  bool get _allGood => !hrAlert && !tempAlert && !spo2Alert && !gasAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _allGood
              ? [AppColors.success.withOpacity(0.1), AppColors.success.withOpacity(0.05)]
              : [AppColors.error.withOpacity(0.1), AppColors.error.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _allGood
              ? AppColors.success.withOpacity(0.4)
              : AppColors.error.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _allGood ? Icons.check_circle_rounded : Icons.warning_rounded,
            color: _allGood ? AppColors.success : AppColors.error,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            _allGood
                ? 'Tous les signes vitaux sont normaux'
                : 'Attention requise !',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _allGood ? AppColors.success : AppColors.error,
            ),
          ),
          if (!_allGood) ...[
            const SizedBox(height: 8),
            if (hrAlert) _alertChip('Fréquence cardiaque'),
            if (tempAlert) _alertChip('Température corporelle'),
            if (spo2Alert) _alertChip('Saturation en oxygène basse'),
            if (gasAlert) _alertChip('Qualité de l\'air dégradée'),
          ],
        ],
      ),
    );
  }

  Widget _alertChip(String label) => Container(
    margin: const EdgeInsets.symmetric(vertical: 3),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.error.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(label, style: const TextStyle(
      fontFamily: 'Nunito', fontSize: 12,
      fontWeight: FontWeight.w700, color: AppColors.error,
    )),
  );
}

class _CameraButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _CameraButton({
    required this.icon, required this.label,
    required this.onTap, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              fontFamily: 'Nunito', fontSize: 13,
              fontWeight: FontWeight.w700, color: color,
            )),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 10,
          color: Colors.white60, fontWeight: FontWeight.w600,
        )),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 13,
          color: Colors.white, fontWeight: FontWeight.w800,
        )),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.surface, child: tabBar);
  }

  @override double get maxExtent => tabBar.preferredSize.height;
  @override double get minExtent => tabBar.preferredSize.height;
  @override bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}