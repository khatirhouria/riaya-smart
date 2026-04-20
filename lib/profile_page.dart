import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'sensor_data_model.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final MedicalUser user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _editMode = false;
  bool _isSaving = false;
  bool _isLoading = true;

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _serviceCtrl;
  late TextEditingController _hospitalCtrl;

  // Données chargées depuis Firestore
  String _role = '';
  String _lastLogin = 'Aujourd\'hui';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _serviceCtrl = TextEditingController();
    _hospitalCtrl = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _serviceCtrl.dispose();
    _hospitalCtrl.dispose();
    super.dispose();
  }

  // ── Charger les données depuis Firestore ──────────────────────
  Future<void> _loadUserData() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameCtrl.text = (data['fullName'] as String?)?.isNotEmpty == true
              ? data['fullName']
              : (firebaseUser.displayName ?? widget.user.fullName);
          _emailCtrl.text = (data['email'] as String?)?.isNotEmpty == true
              ? data['email']
              : (firebaseUser.email ?? widget.user.email);
          _phoneCtrl.text = (data['phone'] as String?)?.isNotEmpty == true
              ? data['phone']
              : widget.user.phone;
          _serviceCtrl.text = (data['service'] as String?)?.isNotEmpty == true
              ? data['service']
              : widget.user.service;
          _hospitalCtrl.text =
              (data['hospital'] as String?)?.isNotEmpty == true
                  ? data['hospital']
                  : widget.user.hospital;
          _role = (data['role'] as String?)?.isNotEmpty == true
              ? data['role']
              : widget.user.role;
        });
      } else {
        // Document Firestore absent → fallback sur Firebase Auth + widget
        setState(() {
          _nameCtrl.text =
              firebaseUser.displayName?.isNotEmpty == true
                  ? firebaseUser.displayName!
                  : widget.user.fullName;
          _emailCtrl.text = firebaseUser.email ?? widget.user.email;
          _phoneCtrl.text = widget.user.phone;
          _serviceCtrl.text = widget.user.service;
          _hospitalCtrl.text = widget.user.hospital;
          _role = widget.user.role;
        });
      }
    } catch (e) {
      // Fallback total sur les données du widget
      setState(() {
        _nameCtrl.text = widget.user.fullName;
        _emailCtrl.text = widget.user.email;
        _phoneCtrl.text = widget.user.phone;
        _serviceCtrl.text = widget.user.service;
        _hospitalCtrl.text = widget.user.hospital;
        _role = widget.user.role;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Sauvegarder dans Firestore ────────────────────────────────
  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Utilisateur non connecté');

      // Mettre à jour Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'service': _serviceCtrl.text.trim(),
        'hospital': _hospitalCtrl.text.trim(),
        'role': _role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Mettre à jour le displayName Firebase Auth
      await FirebaseAuth.instance.currentUser
          ?.updateDisplayName(_nameCtrl.text.trim());

      setState(() => _editMode = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Profil mis à jour avec succès !',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde : $e',
              style: const TextStyle(fontFamily: 'Nunito')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Déconnexion Firebase ──────────────────────────────────────
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Déconnexion',
            style: TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w800)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?',
            style: TextStyle(fontFamily: 'Nunito')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnecter',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // ── Changer le mot de passe ───────────────────────────────────
  Future<void> _handleChangePassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'E-mail de réinitialisation envoyé à $email',
            style: const TextStyle(
                fontFamily: 'Nunito', fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e',
              style: const TextStyle(fontFamily: 'Nunito')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  String get _initials {
    final name = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text
        : widget.user.fullName;
    return name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(
                  _editMode ? Icons.close : Icons.edit_outlined,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _editMode = !_editMode),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _nameCtrl.text.isNotEmpty
                          ? _nameCtrl.text
                          : widget.user.fullName,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _role.isNotEmpty ? _role : widget.user.role,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Edit mode banner
                  if (_editMode)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_note_rounded,
                              color: AppColors.warning, size: 18),
                          SizedBox(width: 8),
                          Text(
                              'Mode édition activé — Modifiez vos informations',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              )),
                        ],
                      ),
                    ),

                  // Informations personnelles
                  _ProfileSection(
                    title: 'Informations personnelles',
                    icon: Icons.person_outline_rounded,
                    children: [
                      _ProfileField(
                        label: 'Nom complet',
                        icon: Icons.badge_outlined,
                        controller: _nameCtrl,
                        editable: _editMode,
                      ),
                      _ProfileField(
                        label: 'Adresse e-mail',
                        icon: Icons.email_outlined,
                        controller: _emailCtrl,
                        editable: false, // email non modifiable
                      ),
                      _ProfileField(
                        label: 'Téléphone',
                        icon: Icons.phone_outlined,
                        controller: _phoneCtrl,
                        editable: _editMode,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Informations professionnelles
                  _ProfileSection(
                    title: 'Informations professionnelles',
                    icon: Icons.local_hospital_outlined,
                    children: [
                      _ProfileFieldStatic(
                        label: 'Rôle',
                        value: _role.isNotEmpty ? _role : widget.user.role,
                        icon: Icons.work_outline_rounded,
                      ),
                      _ProfileField(
                        label: 'Service',
                        icon: Icons.apartment_rounded,
                        controller: _serviceCtrl,
                        editable: _editMode,
                      ),
                      _ProfileField(
                        label: 'Établissement',
                        icon: Icons.local_hospital_outlined,
                        controller: _hospitalCtrl,
                        editable: _editMode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Activité
                  _ProfileSection(
                    title: 'Activité du compte',
                    icon: Icons.bar_chart_rounded,
                    children: [
                      _ActivityRow(
                          label: 'Couveuses surveillées', value: '3'),
                      _ActivityRow(label: 'Alertes traitées', value: '12'),
                      _ActivityRow(
                          label: 'Dernière connexion',
                          value: _lastLogin),
                      _ActivityRow(
                          label: 'E-mail vérifié',
                          value: FirebaseAuth.instance.currentUser
                                      ?.emailVerified ==
                                  true
                              ? '✓ Vérifié'
                              : '✗ Non vérifié'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Boutons
                  if (_editMode)
                    _SaveButton(onSave: _saveProfile, isLoading: _isSaving)
                  else
                    _ActionsSection(
                      onChangePassword: _handleChangePassword,
                      onLogout: _handleLogout,
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentSoft),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    )),
              ],
            ),
          ),
          const Divider(color: AppColors.accentSoft, height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool editable;
  final TextInputType keyboardType;

  const _ProfileField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.editable,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          if (editable)
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                prefixIcon:
                    Icon(icon, color: AppColors.primary, size: 18),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppColors.primaryDark, width: 2),
                ),
              ),
            )
          else
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.text.isNotEmpty
                        ? controller.text
                        : '—',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProfileFieldStatic extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileFieldStatic({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.cardTitle),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(value,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String label;
  final String value;

  const _ActivityRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                color: AppColors.textSecondary,
              )),
          Text(value,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onSave;
  final bool isLoading;

  const _SaveButton({required this.onSave, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoading ? null : onSave,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'ENREGISTRER LES MODIFICATIONS',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  const _ActionsSection({
    required this.onChangePassword,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.lock_outline_rounded,
          label: 'Changer le mot de passe',
          color: AppColors.primary,
          onTap: onChangePassword,
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.notifications_outlined,
          label: 'Préférences de notification',
          color: AppColors.accent,
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _ActionTile(
          icon: Icons.logout_rounded,
          label: 'Se déconnecter',
          color: AppColors.error,
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.textHint, size: 14),
          ],
        ),
      ),
    );
  }
}
