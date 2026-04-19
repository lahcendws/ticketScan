import 'package:flutter/material.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/app_localizations.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        final response = await SupabaseService.signInWithEmail(_emailController.text.trim(), _passwordController.text);
        
        // Vérifier si l'utilisateur est bien connecté (session présente)
        if (response.session != null && mounted) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage()));
        } else if (mounted) {
          _showInfoDialog(
            title: 'Email non confirmé',
            message: 'Veuillez vérifier votre boîte mail et cliquer sur le lien de confirmation pour vous connecter.',
          );
        }
      } else {
        await SupabaseService.signUpWithEmail(_emailController.text.trim(), _passwordController.text);
        if (mounted) {
          _showInfoDialog(
            title: 'Compte créé !',
            message: 'Un email de confirmation vous a été envoyé. Veuillez confirmer votre adresse avant de vous connecter.',
            onConfirm: () => setState(() => _isLogin = true), // Basculer en mode login après inscription
          );
        }
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('Invalid login credentials')) {
        _showErrorSnackBar(AppLocalizations.of(context)?.get('wrong_password') ?? 'Identifiants invalides');
      } else if (errorMsg.contains('Email not confirmed')) {
        _showInfoDialog(title: 'Confirmation requise', message: 'Veuillez confirmer votre email avant de vous connecter.');
      } else {
        _showErrorSnackBar('Une erreur est survenue : ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showInfoDialog({required String title, required String message, VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm?.call();
            },
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _toggleAuthMode() {
    setState(() => _isLogin = !_isLogin);
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.receipt_long, size: 40, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Text('TicketScan', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                            const SizedBox(height: 8),
                            Text(_isLogin ? 'Connectez-vous pour continuer' : 'Créez votre compte'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      CustomTextField(
                        controller: _emailController,
                        label: localizations?.get('email') ?? 'Email',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        label: localizations?.get('password') ?? 'Mot de passe',
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                        validator: (v) => (v == null || v.length < 6) ? 'Mot de passe trop court' : null,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: _isLogin ? (localizations?.get('sign_in') ?? 'Se connecter') : (localizations?.get('sign_up') ?? 'S\'inscrire'),
                        onPressed: _submit,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: _toggleAuthMode,
                          child: Text(_isLogin ? 'Pas encore de compte ? S\'inscrire' : 'Déjà un compte ? Se connecter'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
