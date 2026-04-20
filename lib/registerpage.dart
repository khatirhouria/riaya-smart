import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_theme.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _serviceCtrl = TextEditingController();
  final _hospitalCtrl = TextEditingController();

  // Focus nodes
  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _serviceFocus = FocusNode();
  final _hospitalFocus = FocusNode();

  // State
  String _selectedRole = 'Médecin';
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  int _currentStep = 0;

  // Touched state pour chaque champ
  final Map<String, bool> _touched = {
    'fullName': false,
    'email': false,
    'phone': false,
    'password': false,
    'confirmPass': false,
    'service': false,
    'hospital': false,
    'terms': false,
  };

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ── Regex ─────────────────────────────────────────────────────
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9][a-zA-Z0-9._%+\-]*@[a-zA-Z0-9][a-zA-Z0-9.\-]*\.[a-zA-Z]{2,}$',
  );
  static final _phoneRegex = RegExp(r'^(\+213|0)(5|6|7)[0-9]{8}$');
  static final _nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s'\-]{3,50}$");

  // ── 2 rôles uniquement ────────────────────────────────────────
  final List<Map<String, dynamic>> _roles = [
    {
      'value': 'Médecin',
      'icon': Icons.local_hospital_rounded,
      'color': AppColors.primary,
      'desc': 'Médecin spécialiste / généraliste',
    },
    {
      'value': 'Infirmier(ère)',
      'icon': Icons.medical_services_rounded,
      'color': AppColors.success,
      'desc': 'Infirmier(ère) diplômé(e)',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    // Listeners pour "touched"
    _fullNameFocus.addListener(() {
      if (!_fullNameFocus.hasFocus) setState(() => _touched['fullName'] = true);
    });
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) setState(() => _touched['email'] = true);
    });
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus) setState(() => _touched['phone'] = true);
    });
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus) setState(() => _touched['password'] = true);
    });
    _confirmFocus.addListener(() {
      if (!_confirmFocus.hasFocus) setState(() => _touched['confirmPass'] = true);
    });
    _serviceFocus.addListener(() {
      if (!_serviceFocus.hasFocus) setState(() => _touched['service'] = true);
    });
    _hospitalFocus.addListener(() {
      if (!_hospitalFocus.hasFocus) setState(() => _touched['hospital'] = true);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    for (final c in [
      _fullNameCtrl, _emailCtrl, _phoneCtrl,
      _passwordCtrl, _confirmPassCtrl, _serviceCtrl, _hospitalCtrl,
    ]) {
      c.dispose();
    }
    for (final f in [
      _fullNameFocus, _emailFocus, _phoneFocus,
      _passwordFocus, _confirmFocus, _serviceFocus, _hospitalFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  // VALIDATEURS
  // ══════════════════════════════════════════════════════════════

  String? _validateFullName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Le nom complet est requis';
    if (v.trim().length < 3) return 'Minimum 3 caractères';
    if (v.trim().length > 50) return 'Maximum 50 caractères';
    if (!_nameRegex.hasMatch(v.trim())) {
      return 'Lettres et espaces uniquement (pas de chiffres)';
    }
    if (!v.trim().contains(' ')) {
      return 'Entrez votre prénom et nom — ex: Amira Hadj';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'L\'adresse e-mail est requise';
    if (v.contains(' ')) return 'Aucun espace autorisé';
    if (!v.contains('@')) return 'Format invalide — ex: nom@chu-tlemcen.dz';
    final parts = v.split('@');
    if (parts[0].isEmpty) return 'Nom d\'utilisateur manquant avant @';
    if (parts.length != 2 || parts[1].isEmpty) return 'Domaine manquant après @';
    if (!parts[1].contains('.')) return 'Domaine invalide — ex: chu-tlemcen.dz';
    if (!_emailRegex.hasMatch(v.trim())) {
      return 'Format invalide — ex: prenom.nom@hopital.dz';
    }
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Le numéro de téléphone est requis';
    final cleaned = v.replaceAll(' ', '').replaceAll('-', '');
    if (!_phoneRegex.hasMatch(cleaned)) {
      return 'Format invalide — ex: 0555 123 456 ou +213555123456';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Le mot de passe est requis';
    if (v.length < 8) return 'Minimum 8 caractères';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Au moins 1 lettre majuscule';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Au moins 1 chiffre';
    if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'))) {
      return 'Au moins 1 caractère spécial (!@#\$...)';
    }
    return null;
  }

  String? _validateConfirmPassword(String? v) {
    if (v == null || v.isEmpty) return 'Veuillez confirmer le mot de passe';
    if (v != _passwordCtrl.text) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  String? _validateService(String? v) {
    if (v == null || v.trim().isEmpty) return 'Le service est requis';
    if (v.trim().length < 3) return 'Minimum 3 caractères';
    return null;
  }

  String? _validateHospital(String? v) {
    if (v == null || v.trim().isEmpty) return 'L\'établissement est requis';
    if (v.trim().length < 3) return 'Minimum 3 caractères';
    return null;
  }

  // Force de mot de passe
  int get _passwordStrength {
    final p = _passwordCtrl.text;
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'))) s++;
    return s;
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 1: return AppColors.error;
      case 2: return AppColors.warning;
      case 3: return const Color(0xFF66BB6A);
      case 4: return AppColors.success;
      default: return AppColors.accentSoft;
    }
  }

  String get _strengthLabel {
    switch (_passwordStrength) {
      case 1: return 'Faible';
      case 2: return 'Moyen';
      case 3: return 'Bon';
      case 4: return 'Excellent';
      default: return '';
    }
  }

  // ── Valider étape 0 ──────────────────────────────────────────
  bool _validateStep0() {
    setState(() {
      _touched['fullName'] = true;
      _touched['email'] = true;
      _touched['phone'] = true;
      _touched['service'] = true;
      _touched['hospital'] = true;
    });

    final nameErr = _validateFullName(_fullNameCtrl.text);
    final emailErr = _validateEmail(_emailCtrl.text);
    final phoneErr = _validatePhone(_phoneCtrl.text);
    final serviceErr = _validateService(_serviceCtrl.text);
    final hospitalErr = _validateHospital(_hospitalCtrl.text);

    if (nameErr != null || emailErr != null || phoneErr != null ||
        serviceErr != null || hospitalErr != null) {
      _showErrorSnack('Veuillez corriger les erreurs avant de continuer.');
      return false;
    }
    return true;
  }

  // ── Valider étape 1 ──────────────────────────────────────────
  bool _validateStep1() {
    setState(() {
      _touched['password'] = true;
      _touched['confirmPass'] = true;
      _touched['terms'] = true;
    });

    final passErr = _validatePassword(_passwordCtrl.text);
    final confirmErr = _validateConfirmPassword(_confirmPassCtrl.text);

    if (passErr != null || confirmErr != null) {
      _showErrorSnack('Veuillez corriger les erreurs du mot de passe.');
      return false;
    }
    if (!_acceptTerms) {
      _showErrorSnack('Veuillez accepter les conditions d\'utilisation.');
      return false;
    }
    return true;
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg,
                style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Inscription ──────────────────────────────────────────────
  void _handleRegister() async {
    if (!_validateStep1()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Créer le compte Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      final uid = credential.user!.uid;

      // 2. Mettre à jour le displayName Firebase Auth
      await credential.user!.updateDisplayName(_fullNameCtrl.text.trim());

      // 3. Sauvegarder TOUTES les données dans Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'fullName': _fullNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'role': _selectedRole,
        'service': _serviceCtrl.text.trim(),
        'hospital': _hospitalCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Envoyer e-mail de vérification
      await credential.user!.sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text('Compte créé avec succès ! Vérifiez votre e-mail.',
                    style: TextStyle(
                        fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Cette adresse e-mail est déjà utilisée.';
          break;
        case 'invalid-email':
          message = 'L\'adresse e-mail est invalide.';
          break;
        case 'weak-password':
          message = 'Le mot de passe est trop faible.';
          break;
        case 'network-request-failed':
          message = 'Erreur réseau. Vérifiez votre connexion internet.';
          break;
        default:
          message = 'Erreur : ${e.message ?? e.code}';
      }
      _showErrorSnack(message);
    } catch (e) {
      _showErrorSnack('Erreur inattendue : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStepProgress(),
                        const SizedBox(height: 24),
                        if (_currentStep == 0) _buildStep0(),
                        if (_currentStep == 1) _buildStep1(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -20, right: -20,
              child: _circle(100, 0.08)),
          Positioned(bottom: 10, left: -15,
              child: _circle(70, 0.07)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.monitor_heart_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 10),
                const Text('RIAYA SMART',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 22,
                      fontWeight: FontWeight.w900, color: Colors.white,
                      letterSpacing: 2,
                    )),
                const SizedBox(height: 3),
                const Text('Créer un nouveau compte',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 13,
                      fontWeight: FontWeight.w500, color: Colors.white70,
                    )),
              ],
            ),
          ),
          // Bouton retour
          Positioned(
            top: 40,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(opacity),
    ),
  );

  // ── Barre de progression ──────────────────────────────────────
  Widget _buildStepProgress() {
    return Column(
      children: [
        Row(
          children: List.generate(2, (i) {
            final active = i <= _currentStep;
            final done = i < _currentStep;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 6,
                      margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
                      decoration: BoxDecoration(
                        gradient: active ? AppColors.primaryGradient : null,
                        color: active ? null : AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _currentStep == 0
                  ? '📋 Étape 1/2 — Informations personnelles'
                  : '🔒 Étape 2/2 — Sécurité du compte',
              style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 13,
                fontWeight: FontWeight.w700, color: AppColors.primary,
              ),
            ),
            Text(
              '${_currentStep + 1} / 2',
              style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ÉTAPE 0 — Informations personnelles
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sélecteur de rôle ────────────────────────────────
        _sectionTitle(Icons.work_outline_rounded, 'Rôle professionnel'),
        const SizedBox(height: 12),
        _buildRoleSelector(),
        const SizedBox(height: 20),

        // ── Nom complet ──────────────────────────────────────
        _sectionTitle(Icons.person_outline_rounded, 'Informations personnelles'),
        const SizedBox(height: 12),
        _buildField(
          label: 'Nom complet',
          hint: 'ex: Amira Hadj',
          icon: Icons.badge_outlined,
          controller: _fullNameCtrl,
          focusNode: _fullNameFocus,
          nextFocus: _emailFocus,
          touchedKey: 'fullName',
          validator: _validateFullName,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZÀ-ÿ\s'\-]")),
          ],
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),

        // ── Email ────────────────────────────────────────────
        _buildField(
          label: 'Adresse e-mail',
          hint: 'ex: amira.hadj@chu-tlemcen.dz',
          icon: Icons.alternate_email_rounded,
          controller: _emailCtrl,
          focusNode: _emailFocus,
          nextFocus: _phoneFocus,
          touchedKey: 'email',
          validator: _validateEmail,
          keyboardType: TextInputType.emailAddress,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
            TextInputFormatter.withFunction((o, n) =>
                n.copyWith(text: n.text.toLowerCase())),
          ],
        ),
        const SizedBox(height: 14),

        // ── Téléphone ────────────────────────────────────────
        _buildField(
          label: 'Numéro de téléphone',
          hint: 'ex: 0555 123 456',
          icon: Icons.phone_outlined,
          controller: _phoneCtrl,
          focusNode: _phoneFocus,
          nextFocus: _serviceFocus,
          touchedKey: 'phone',
          validator: _validatePhone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\+\s\-]')),
            LengthLimitingTextInputFormatter(14),
          ],
        ),
        const SizedBox(height: 20),

        // ── Informations professionnelles ────────────────────
        _sectionTitle(Icons.local_hospital_outlined, 'Informations professionnelles'),
        const SizedBox(height: 12),

        _buildField(
          label: 'Service',
          hint: 'ex: Néonatologie',
          icon: Icons.apartment_rounded,
          controller: _serviceCtrl,
          focusNode: _serviceFocus,
          nextFocus: _hospitalFocus,
          touchedKey: 'service',
          validator: _validateService,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),

        _buildField(
          label: 'Établissement / Hôpital',
          hint: 'ex: CHU Tlemcen',
          icon: Icons.local_hospital_outlined,
          controller: _hospitalCtrl,
          focusNode: _hospitalFocus,
          touchedKey: 'hospital',
          validator: _validateHospital,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 28),

        // ── Bouton Suivant ───────────────────────────────────
        _buildPrimaryButton(
          label: 'SUIVANT',
          icon: Icons.arrow_forward_rounded,
          onTap: () {
            if (_validateStep0()) {
              setState(() {
                _currentStep = 1;
                _animCtrl.reset();
                _animCtrl.forward();
              });
            }
          },
        ),
        const SizedBox(height: 16),
        _buildLoginLink(),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ÉTAPE 1 — Sécurité
  // ══════════════════════════════════════════════════════════════
  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.security_rounded, 'Sécurité du compte'),
        const SizedBox(height: 12),

        // ── Mot de passe ─────────────────────────────────────
        _buildPasswordField(
          label: 'Mot de passe',
          hint: 'Minimum 8 caractères',
          controller: _passwordCtrl,
          focusNode: _passwordFocus,
          nextFocus: _confirmFocus,
          touchedKey: 'password',
          validator: _validatePassword,
          obscure: _obscurePass,
          onToggle: () => setState(() => _obscurePass = !_obscurePass),
        ),

        // Barre de force
        const SizedBox(height: 8),
        _buildStrengthBar(),
        const SizedBox(height: 6),

        // Règles du mot de passe
        _buildPasswordRules(),
        const SizedBox(height: 14),

        // ── Confirmation ─────────────────────────────────────
        _buildPasswordField(
          label: 'Confirmer le mot de passe',
          hint: 'Répétez le mot de passe',
          controller: _confirmPassCtrl,
          focusNode: _confirmFocus,
          touchedKey: 'confirmPass',
          validator: _validateConfirmPassword,
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 20),

        // ── Conditions ───────────────────────────────────────
        _buildTermsCheckbox(),

        if (_touched['terms'] == true && !_acceptTerms)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Vous devez accepter les conditions pour continuer',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 11, color: AppColors.error,
              ),
            ),
          ),

        const SizedBox(height: 24),

        // ── Boutons ──────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  _currentStep = 0;
                  _animCtrl.reset();
                  _animCtrl.forward();
                }),
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.primary, size: 18),
                label: const Text('Retour',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    )),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildPrimaryButton(
                label: 'CRÉER LE COMPTE',
                icon: Icons.check_rounded,
                onTap: _handleRegister,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildLoginLink(),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // WIDGETS HELPERS
  // ══════════════════════════════════════════════════════════════

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(
          fontFamily: 'Nunito', fontSize: 15,
          fontWeight: FontWeight.w800, color: AppColors.textPrimary,
        )),
      ],
    );
  }

  // ── Sélecteur rôle (Médecin / Infirmier) ─────────────────────
  Widget _buildRoleSelector() {
    return Row(
      children: _roles.map((role) {
        final isSelected = _selectedRole == role['value'];
        final color = role['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedRole = role['value']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(
                right: role['value'] == 'Médecin' ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? color : AppColors.accentSoft,
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 10, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Column(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.15)
                          : AppColors.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(role['icon'] as IconData,
                        color: isSelected ? color : AppColors.textHint,
                        size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(role['value'],
                      style: TextStyle(
                        fontFamily: 'Nunito', fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? color : AppColors.textSecondary,
                      )),
                  const SizedBox(height: 2),
                  Text(role['desc'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito', fontSize: 10,
                        color: AppColors.textHint,
                      )),
                  const SizedBox(height: 6),
                  // Indicateur sélection
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isSelected ? 24 : 0,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Champ texte générique ─────────────────────────────────────
  Widget _buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String touchedKey,
    required String? Function(String?) validator,
    List<TextInputFormatter>? inputFormatters,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    final error = _touched[touchedKey] == true ? validator(controller.text) : null;
    final hasValue = controller.text.isNotEmpty;
    final isValid = hasValue && error == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 13,
            fontWeight: FontWeight.w700, color: AppColors.textPrimary,
          )),
          const Text(' *', style: TextStyle(
              color: AppColors.error, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: (_) {
            if (_touched[touchedKey] == true) setState(() {});
          },
          onFieldSubmitted: (_) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            }
          },
          style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 15,
            fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Nunito', fontSize: 13, color: AppColors.textHint,
            ),
            prefixIcon: Icon(icon,
                color: error != null
                    ? AppColors.error
                    : isValid
                    ? AppColors.success
                    : AppColors.primary,
                size: 20),
            suffixIcon: hasValue
                ? Icon(
                isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isValid ? AppColors.success : AppColors.error,
                size: 20)
                : null,
            errorText: error,
            errorStyle: const TextStyle(
              fontFamily: 'Nunito', fontSize: 11, color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  // ── Champ mot de passe ───────────────────────────────────────
  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required String touchedKey,
    required String? Function(String?) validator,
    required bool obscure,
    required VoidCallback onToggle,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    final error = _touched[touchedKey] == true ? validator(controller.text) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label, style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 13,
            fontWeight: FontWeight.w700, color: AppColors.textPrimary,
          )),
          const Text(' *', style: TextStyle(
              color: AppColors.error, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: (_) {
            if (_touched[touchedKey] == true) setState(() {});
            if (touchedKey == 'password') setState(() {});
          },
          onFieldSubmitted: (_) {
            if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
          },
          style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 15,
            fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Nunito', fontSize: 13, color: AppColors.textHint,
            ),
            prefixIcon: Icon(Icons.lock_outline_rounded,
                color: error != null ? AppColors.error : AppColors.primary,
                size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textHint, size: 20,
              ),
              onPressed: onToggle,
            ),
            errorText: error,
            errorStyle: const TextStyle(
              fontFamily: 'Nunito', fontSize: 11, color: AppColors.error,
            ),
          ),
        ),
      ],
    );
  }

  // ── Barre de force du mot de passe ───────────────────────────
  Widget _buildStrengthBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) => Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              height: 5,
              decoration: BoxDecoration(
                color: i < _passwordStrength ? _strengthColor : AppColors.accentSoft,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          )),
        ),
        if (_passwordCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text('Force : $_strengthLabel',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 11,
                fontWeight: FontWeight.w700, color: _strengthColor,
              )),
        ],
      ],
    );
  }

  // ── Règles du mot de passe ───────────────────────────────────
  Widget _buildPasswordRules() {
    final p = _passwordCtrl.text;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Le mot de passe doit contenir :',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 11,
                fontWeight: FontWeight.w700, color: AppColors.textSecondary,
              )),
          const SizedBox(height: 6),
          _ruleRow('Minimum 8 caractères', p.length >= 8),
          _ruleRow('Au moins 1 majuscule (A-Z)', p.contains(RegExp(r'[A-Z]'))),
          _ruleRow('Au moins 1 chiffre (0-9)', p.contains(RegExp(r'[0-9]'))),
          _ruleRow('Au moins 1 caractère spécial (!@#\$...)',
              p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'))),
        ],
      ),
    );
  }

  Widget _ruleRow(String text, bool valid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: valid ? AppColors.success : AppColors.textHint,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(
            fontFamily: 'Nunito', fontSize: 11,
            color: valid ? AppColors.success : AppColors.textHint,
            fontWeight: valid ? FontWeight.w600 : FontWeight.w400,
          )),
        ],
      ),
    );
  }

  // ── Checkbox conditions ──────────────────────────────────────
  Widget _buildTermsCheckbox() {
    final hasError = _touched['terms'] == true && !_acceptTerms;
    return GestureDetector(
      onTap: () => setState(() {
        _acceptTerms = !_acceptTerms;
        _touched['terms'] = true;
      }),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _acceptTerms
              ? AppColors.success.withOpacity(0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasError
                ? AppColors.error.withOpacity(0.5)
                : _acceptTerms
                ? AppColors.success.withOpacity(0.4)
                : AppColors.accentSoft,
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: _acceptTerms ? AppColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: hasError
                      ? AppColors.error
                      : _acceptTerms
                      ? AppColors.success
                      : AppColors.textHint,
                  width: 1.5,
                ),
              ),
              child: _acceptTerms
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'J\'accepte les conditions d\'utilisation et la politique de confidentialité de RIAYA SMART. '
                    'Ces données sont utilisées uniquement dans le cadre médical.',
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 12,
                  color: AppColors.textSecondary, height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bouton principal ─────────────────────────────────────────
  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: isLoading
              ? const LinearGradient(
              colors: [Color(0xFF9BBECE), Color(0xFF9BBECE)])
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading
              ? []
              : [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 14, offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5))
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(
                fontFamily: 'Nunito', fontSize: 15,
                fontWeight: FontWeight.w800, color: Colors.white,
                letterSpacing: 0.5,
              )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Lien connexion ───────────────────────────────────────────
  Widget _buildLoginLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontFamily: 'Nunito', fontSize: 14,
              color: AppColors.textSecondary,
            ),
            children: [
              TextSpan(text: 'Déjà un compte ? '),
              TextSpan(
                text: 'Se connecter',
                style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
