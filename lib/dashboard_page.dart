import 'dart:async';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'sensor_data_model.dart';
import 'incubator_detail_page.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  final MedicalUser user;
  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  Timer? _refreshTimer;

  final List<String> _incubatorIds = ['INC-001', 'INC-002', 'INC-003'];
  final Map<String, SensorData> _sensorsData = {};
  final Map<String, BabyProfile> _babyProfiles = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadData());
  }

  void _loadData() {
    setState(() {
      for (final id in _incubatorIds) {
        _sensorsData[id]  = SensorData.mock(id);
        _babyProfiles[id] = BabyProfile.forIncubator(id); // ← profil fixe par couveuse
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(
            user: widget.user,
            incubatorIds: _incubatorIds,
            sensorsData: _sensorsData,
            babyProfiles: _babyProfiles,
          ),
          _AlertsTab(
            sensorsData: _sensorsData,
            babyProfiles: _babyProfiles,
          ),
          ProfilePage(user: widget.user),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selected: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        alertCount: _sensorsData.values
            .where((s) =>
        s.gasAlert ||
            s.heartRate > 180 ||
            s.heartRate < 100 ||
            s.spo2 < 94)
            .length,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME TAB
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final MedicalUser user;
  final List<String> incubatorIds;
  final Map<String, SensorData> sensorsData;
  final Map<String, BabyProfile> babyProfiles;

  const _HomeTab({
    required this.user,
    required this.incubatorIds,
    required this.sensorsData,
    required this.babyProfiles,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting =
    hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    final alertCount = sensorsData.values
        .where((s) =>
    s.gasAlert ||
        s.heartRate > 180 ||
        s.heartRate < 100 ||
        s.spo2 < 94)
        .length;

    return CustomScrollView(
      slivers: [
        // ── App Bar ────────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          elevation: 0,
          backgroundColor: AppColors.primaryDark,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration:
              const BoxDecoration(gradient: AppColors.primaryGradient),
              child: Stack(
                children: [
                  Positioned(
                    top: -20,
                    right: -20,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              width: 14,
                              height: 14,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'RIAYA SMART',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white60,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.circle,
                                      color: Color(0xFF4CAF50), size: 7),
                                  SizedBox(width: 4),
                                  Text(
                                    'Temps réel',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 10,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$greeting, ${user.fullName.split(' ').last}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${user.role}  ·  ${user.service}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 24),
                  onPressed: () {},
                ),
                if (alertCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$alertCount',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // ── Bandeau alerte critique ────────────────────────────────────────
        if (alertCount > 0)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.error.withOpacity(0.4), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.priority_high_rounded,
                        color: AppColors.error, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$alertCount couveuse${alertCount > 1 ? 's' : ''} '
                              'nécessite${alertCount > 1 ? 'nt' : ''} votre attention',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                        ),
                        const Text(
                          'Vérifiez les paramètres ci-dessous',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Stats rapides ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _QuickStats(
              incubatorCount: incubatorIds.length,
              alertCount: alertCount,
            ),
          ),
        ),

        // ── Titre liste ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Couveuses actives',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${incubatorIds.length} actives',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Liste des couveuses ────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) {
                final id = incubatorIds[i];
                final sensor = sensorsData[id];
                final baby = babyProfiles[id];
                if (sensor == null || baby == null) return const SizedBox();
                return _IncubatorCard(
                  incubatorId: id,
                  sensor: sensor,
                  baby: baby,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IncubatorDetailPage(
                        incubatorId: id,
                        baby: baby,
                        initialData: sensor,
                      ),
                    ),
                  ),
                );
              },
              childCount: incubatorIds.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QUICK STATS
// ─────────────────────────────────────────────────────────────────────────────
class _QuickStats extends StatelessWidget {
  final int incubatorCount;
  final int alertCount;
  const _QuickStats({required this.incubatorCount, required this.alertCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Couveuses',
            value: '$incubatorCount',
            icon: Icons.crib_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Bébés',
            value: '$incubatorCount',
            icon: Icons.child_care_rounded,
            color: AppColors.heartColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            label: 'Alertes',
            value: '$alertCount',
            icon: alertCount > 0
                ? Icons.warning_amber_rounded
                : Icons.check_circle_outline_rounded,
            color: alertCount > 0 ? AppColors.error : AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10,
              color: AppColors.textHint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INCUBATOR CARD
// ─────────────────────────────────────────────────────────────────────────────
class _IncubatorCard extends StatelessWidget {
  final String incubatorId;
  final SensorData sensor;
  final BabyProfile baby;
  final VoidCallback onTap;

  const _IncubatorCard({
    required this.incubatorId,
    required this.sensor,
    required this.baby,
    required this.onTap,
  });

  bool get _hasAlert =>
      sensor.gasAlert ||
          sensor.heartRate > 180 ||
          sensor.heartRate < 100 ||
          sensor.spo2 < 94 ||
          sensor.incubatorTemperature < 36 ||
          sensor.incubatorTemperature > 38;

  String get _statusLabel {
    if (sensor.gasAlert) return '⚠ Qualité air';
    if (sensor.heartRate > 180) return '⚠ Tachycardie';
    if (sensor.heartRate < 100) return '⚠ Bradycardie';
    if (sensor.spo2 < 94) return '⚠ SpO₂ bas';
    if (sensor.incubatorTemperature < 36 ||
        sensor.incubatorTemperature > 38) return '⚠ Temp. anormale';
    return '✓ Stable';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hasAlert
                ? AppColors.error.withOpacity(0.5)
                : AppColors.accentSoft,
            width: _hasAlert ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (_hasAlert ? AppColors.error : AppColors.primary)
                  .withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── En-tête bébé ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: _hasAlert
                          ? LinearGradient(colors: [
                        AppColors.error.withOpacity(0.7),
                        AppColors.error,
                      ])
                          : AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '${baby.firstName[0]}${baby.lastName[0]}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${baby.firstName} ${baby.lastName}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Text(incubatorId,
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    color: AppColors.textHint)),
                            const Text('  ·  ',
                                style: TextStyle(color: AppColors.textHint)),
                            Text('${baby.gestationalAge} SA',
                                style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 11,
                                    color: AppColors.textHint)),
                            const Text('  ·  ',
                                style: TextStyle(color: AppColors.textHint)),
                            Text(
                              '${DateTime.now().difference(baby.birthDate).inDays} j de vie',
                              style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11,
                                  color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badge statut
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _hasAlert
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _hasAlert
                            ? AppColors.error.withOpacity(0.3)
                            : AppColors.success.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _statusLabel,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color:
                        _hasAlert ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.accentSoft, height: 1),

            // ── Vitaux principaux ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _VitalTile(
                      label: 'Fréq.',
                      value: '${sensor.heartRate}',
                      unit: 'bpm',
                      icon: Icons.favorite_rounded,
                      color: AppColors.heartColor,
                      isAlert: sensor.heartRate > 180 || sensor.heartRate < 100,
                    )),
                    _VitalDivider(),
                    Expanded(child: _VitalTile(
                      label: 'SpO₂',
                      value: '${sensor.spo2.toInt()}',
                      unit: '%',
                      icon: Icons.bloodtype_outlined,
                      color: AppColors.spo2Color,
                      isAlert: sensor.spo2 < 94,
                    )),
                    _VitalDivider(),
                    Expanded(child: _VitalTile(
                      label: 'Temp.',
                      value: sensor.incubatorTemperature.toStringAsFixed(1),
                      unit: '°C',
                      icon: Icons.thermostat_rounded,
                      color: AppColors.tempColor,
                      isAlert: sensor.incubatorTemperature < 36 ||
                          sensor.incubatorTemperature > 38,
                    )),
                    _VitalDivider(),
                    Expanded(child: _VitalTile(
                      label: 'Poids',
                      value: '${sensor.babyWeight.toInt()}',
                      unit: 'g',
                      icon: Icons.monitor_weight_outlined,
                      color: AppColors.weightColor,
                    )),
                    _VitalDivider(),
                    Expanded(child: _VitalTile(
                      label: 'Humid.',
                      value: '${sensor.incubatorHumidity.toInt()}',
                      unit: '%',
                      icon: Icons.water_drop_outlined,
                      color: AppColors.humidityColor,
                      isAlert: sensor.incubatorHumidity < 50 ||
                          sensor.incubatorHumidity > 70,
                    )),
                  ],
                ),
              ),
            ),

            // ── Bouton détails ─────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Voir le dossier complet',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      color: AppColors.primary, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isAlert;

  const _VitalTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isAlert ? AppColors.error : color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: displayColor, size: 14),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: displayColor,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: displayColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 8,
            color: AppColors.textHint,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _VitalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: AppColors.accentSoft);
}

// ─────────────────────────────────────────────────────────────────────────────
// ALERTS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _AlertsTab extends StatelessWidget {
  final Map<String, SensorData> sensorsData;
  final Map<String, BabyProfile> babyProfiles;

  const _AlertsTab({
    required this.sensorsData,
    required this.babyProfiles,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> alerts = [];

    sensorsData.forEach((id, data) {
      final baby = babyProfiles[id];
      final label = baby != null
          ? '${baby.firstName} ${baby.lastName} · $id'
          : id;

      if (data.heartRate > 180 || data.heartRate < 100) {
        alerts.add({
          'icon': Icons.favorite_rounded,
          'color': AppColors.heartColor,
          'title': 'Fréquence cardiaque anormale',
          'detail': data.heartRate > 180
              ? 'Tachycardie — ${data.heartRate} bpm'
              : 'Bradycardie — ${data.heartRate} bpm',
          'incubator': label,
          'level': 'Critique',
          'levelColor': AppColors.error,
        });
      }
      if (data.spo2 < 94) {
        alerts.add({
          'icon': Icons.bloodtype_outlined,
          'color': AppColors.spo2Color,
          'title': 'Saturation en oxygène basse',
          'detail': '${data.spo2.toStringAsFixed(1)} % — Norme : > 94 %',
          'incubator': label,
          'level': 'Critique',
          'levelColor': AppColors.error,
        });
      }
      if (data.gasAlert) {
        alerts.add({
          'icon': Icons.air_rounded,
          'color': AppColors.gasColor,
          'title': "Qualité de l'air dégradée",
          'detail':
          '${data.gasLevel.toStringAsFixed(1)} ppm — Seuil : > 30 ppm',
          'incubator': label,
          'level': 'Urgent',
          'levelColor': AppColors.error,
        });
      }
      if (data.incubatorTemperature < 36 ||
          data.incubatorTemperature > 38) {
        alerts.add({
          'icon': Icons.thermostat_rounded,
          'color': AppColors.tempColor,
          'title': 'Température hors norme',
          'detail':
          '${data.incubatorTemperature.toStringAsFixed(1)} °C — Norme : 36–38 °C',
          'incubator': label,
          'level': 'Avertissement',
          'levelColor': AppColors.warning,
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text(
          'Alertes',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        actions: [
          if (alerts.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${alerts.length} active${alerts.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: alerts.isEmpty
          ? const _NoAlertsView()
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_services_outlined,
                    color: AppColors.error, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${alerts.length} alerte${alerts.length > 1 ? 's' : ''} '
                        'nécessite${alerts.length > 1 ? 'nt' : ''} une intervention',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...alerts.map((a) => _AlertTile(
            icon: a['icon'],
            color: a['color'],
            title: a['title'],
            detail: a['detail'],
            incubator: a['incubator'],
            level: a['level'],
            levelColor: a['levelColor'],
          )),
        ],
      ),
    );
  }
}

class _NoAlertsView extends StatelessWidget {
  const _NoAlertsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: AppColors.success, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tout est normal',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Aucune alerte active en ce moment',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String incubator;
  final String level;
  final Color levelColor;

  const _AlertTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.incubator,
    required this.level,
    required this.levelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: levelColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: levelColor.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$incubator  ·  $detail',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              level,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: levelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAVIGATION
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  final int alertCount;

  const _BottomNav({
    required this.selected,
    required this.onTap,
    required this.alertCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                index: 0,
                selected: selected,
                onTap: onTap,
                icon: Icons.grid_view_rounded,
                activeIcon: Icons.grid_view_rounded,
                label: 'Tableau de bord',
              ),
              _NavItem(
                index: 1,
                selected: selected,
                onTap: onTap,
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications_rounded,
                label: 'Alertes',
                badgeCount: alertCount,
              ),
              _NavItem(
                index: 2,
                selected: selected,
                onTap: onTap,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int selected;
  final ValueChanged<int> onTap;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;

  const _NavItem({
    required this.index,
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textHint,
                    size: 22,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: 0,
                    right: 4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight:
                isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}