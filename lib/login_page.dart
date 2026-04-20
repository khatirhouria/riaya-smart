import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';
import 'registerpage.dart';
import 'dashboard_page.dart';
import 'sensor_data_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _rememberMe = false;
  bool _emailTouched = false;
  bool _passTouched = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9][a-zA-Z0-9._%+\-]*@[a-zA-Z0-9][a-zA-Z0-9.\-]*\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) setState(() => _emailTouched = true);
    });
    _passFocus.addListener(() {
      if (!_passFocus.hasFocus) setState(() => _passTouched = true);
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'L\'adresse e-mail est requise';
    if (v.contains(' ')) return 'Aucun espace autorisé dans l\'e-mail';
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

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Le mot de passe est requis';
    if (v.length < 6) return 'Minimum 6 caractères';
    return null;
  }

  // ══════════════════════════════════════════════════════════════
  // FIREBASE LOGIN
  // ══════════════════════════════════════════════════════════════
  void _handleLogin() async {
    setState(() {
      _emailTouched = true;
      _passTouched = true;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        _showErrorSnack('Erreur d\'authentification. Réessayez.');
        return;
      }

      if (!mounted) return;

      // Déduire le rôle depuis le displayName ou l'email
      final displayName = firebaseUser.displayName ?? '';
      final email = firebaseUser.email ?? _emailCtrl.text;
      final role = email.contains('infirmier') ? 'Infirmier(ère)' : 'Médecin';
      final fullName = displayName.isNotEmpty
          ? displayName
          : (role == 'Médecin' ? 'Dr. Utilisateur' : 'Inf. Utilisateur');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            user: MedicalUser(
              id: firebaseUser.uid,
              fullName: fullName,
              email: email,
              phone: '',
              role: role,
              service: 'Néonatologie',
              hospital: 'CHU Tlemcen',
            ),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun compte trouvé avec cet e-mail.';
          break;
        case 'wrong-password':
          message = 'Mot de passe incorrect.';
          break;
        case 'invalid-email':
          message = 'Adresse e-mail invalide.';
          break;
        case 'user-disabled':
          message = 'Ce compte a été désactivé.';
          break;
        case 'too-many-requests':
          message = 'Trop de tentatives. Réessayez plus tard.';
          break;
        case 'network-request-failed':
          message = 'Erreur réseau. Vérifiez votre connexion internet.';
          break;
        case 'invalid-credential':
          message = 'E-mail ou mot de passe incorrect.';
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

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

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
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeCard(),
                          const SizedBox(height: 28),
                          _buildEmailField(),
                          const SizedBox(height: 16),
                          _buildPasswordField(),
                          const SizedBox(height: 12),
                          _buildRememberRow(),
                          const SizedBox(height: 28),
                          _buildLoginButton(),
                          const SizedBox(height: 24),
                          _buildDivider(),
                          const SizedBox(height: 20),
                          _buildRegisterLink(),
                          const SizedBox(height: 16),
                          _buildMedicalNote(),
                        ],
                      ),
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

  Widget _buildHeader() {
    return Container(
      height: 260,
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
          Positioned(top: -30, right: -30, child: _circle(130, 0.08)),
          Positioned(top: 60, right: 40, child: _circle(60, 0.10)),
          Positioned(bottom: 20, left: -20, child: _circle(90, 0.07)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Container(
                  width: 74, height: 74,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.monitor_heart_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 14),
                const Text('RIAYA SMART',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 26,
                      fontWeight: FontWeight.w900, color: Colors.white,
                      letterSpacing: 2.5,
                    )),
                const SizedBox(height: 4),
                Text('Couveuse Intelligente Connectée',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 13,
                      color: Colors.white.withOpacity(0.75),
                    )),
                const SizedBox(height: 6),
                const Text('Connexion à votre compte',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 15,
                      fontWeight: FontWeight.w600, color: Colors.white,
                    )),
              ],
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

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.baby_changing_station_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bienvenue sur RIAYA',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 15,
                      fontWeight: FontWeight.w800, color: AppColors.textPrimary,
                    )),
                SizedBox(height: 2),
                Text('Surveillance en temps réel de votre bébé',
                    style: TextStyle(
                      fontFamily: 'Nunito', fontSize: 12,
                      color: AppColors.textSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    final error = _emailTouched ? _validateEmail(_emailCtrl.text) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Adresse e-mail',
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 13,
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                )),
            const Text(' *',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: _emailCtrl,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
            TextInputFormatter.withFunction((oldValue, newValue) =>
                newValue.copyWith(text: newValue.text.toLowerCase())),
          ],
          validator: _validateEmail,
          onChanged: (_) {
            if (_emailTouched) setState(() {});
          },
          onFieldSubmitted: (_) =>
              FocusScope.of(context).requestFocus(_passFocus),
          style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 15,
            fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'ex: nom.prenom@chu-tlemcen.dz',
            hintStyle: const TextStyle(
              fontFamily: 'Nunito', fontSize: 13, color: AppColors.textHint,
            ),
            prefixIcon: Icon(
              Icons.alternate_email_rounded,
              color: error != null ? AppColors.error : AppColors.primary,
              size: 20,
            ),
            suffixIcon: _emailCtrl.text.isNotEmpty
                ? Icon(
              error == null
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: error == null ? AppColors.success : AppColors.error,
              size: 20,
            )
                : null,
            errorText: error,
            errorStyle: const TextStyle(
              fontFamily: 'Nunito', fontSize: 11, color: AppColors.error,
            ),
          ),
        ),
        if (error == null && _emailCtrl.text.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 5, left: 4),
            child: Text(
              '💡 Format : prenom.nom@etablissement.dz',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 11, color: AppColors.textHint,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField() {
    final error = _passTouched ? _validatePassword(_passCtrl.text) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Mot de passe',
                style: TextStyle(
                  fontFamily: 'Nunito', fontSize: 13,
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                )),
            const Text(' *',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: _passCtrl,
          focusNode: _passFocus,
          obscureText: _obscurePass,
          textInputAction: TextInputAction.done,
          validator: _validatePassword,
          onChanged: (_) {
            if (_passTouched) setState(() {});
          },
          onFieldSubmitted: (_) => _handleLogin(),
          style: const TextStyle(
            fontFamily: 'Nunito', fontSize: 15,
            fontWeight: FontWeight.w600, color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Votre mot de passe',
            hintStyle: const TextStyle(
              fontFamily: 'Nunito', fontSize: 13, color: AppColors.textHint,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: error != null ? AppColors.error : AppColors.primary,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textHint, size: 20,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
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

  Widget _buildRememberRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => setState(() => _rememberMe = !_rememberMe),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: _rememberMe ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _rememberMe ? AppColors.primary : AppColors.textHint,
                    width: 1.5,
                  ),
                ),
                child: _rememberMe
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 8),
              const Text('Se souvenir de moi',
                  style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 13,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
        ),
        TextButton(
          onPressed: _handleForgotPassword,
          style: TextButton.styleFrom(
              padding: EdgeInsets.zero, minimumSize: Size.zero),
          child: const Text('Mot de passe oublié ?',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 13,
                fontWeight: FontWeight.w700, color: AppColors.primary,
              )),
        ),
      ],
    );
  }

  void _handleForgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || _validateEmail(email) != null) {
      _showErrorSnack('Entrez d\'abord votre adresse e-mail valide.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('E-mail de réinitialisation envoyé à $email',
              style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showErrorSnack('Erreur : ${e.message ?? e.code}');
    }
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLogin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? const LinearGradient(
              colors: [Color(0xFF9BBECE), Color(0xFF9BBECE)])
              : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isLoading
              ? []
              : [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16, offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          )
              : const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('SE CONNECTER',
                  style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 16,
                    fontWeight: FontWeight.w800, color: Colors.white,
                    letterSpacing: 0.8,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.accentSoft, thickness: 1.5)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('ou',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 13,
                fontWeight: FontWeight.w600, color: AppColors.textHint,
              )),
        ),
        Expanded(child: Divider(color: AppColors.accentSoft, thickness: 1.5)),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
              fontFamily: 'Nunito', fontSize: 14,
              color: AppColors.textSecondary),
          children: [
            const TextSpan(text: 'Pas encore de compte ? '),
            WidgetSpan(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterPage(),
                    ),
                  );
                },
                child: const Text(
                  'S\'inscrire',
                  style: TextStyle(
                    fontFamily: 'Nunito', fontSize: 14,
                    fontWeight: FontWeight.w800, color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withOpacity(0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.medical_services_outlined,
              color: AppColors.warning, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Application réservée au personnel médical autorisé.',
              style: TextStyle(
                fontFamily: 'Nunito', fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
