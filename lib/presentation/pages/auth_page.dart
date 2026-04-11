import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../core/services/firebase_service.dart';
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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
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
        // await FirebaseService.signInWithEmail(
        await SupabaseService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // await FirebaseService.signUpWithEmail(
        await SupabaseService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      
      if (mounted) {
        // Redirection directe vers HomePage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } on Exception catch (e) {
      _showErrorSnackBar(_getErrorMessage(e));
    } catch (e) {
      print('Auth error: $e'); // Pour le débug
      _showErrorSnackBar('Une erreur est survenue. Veuillez réessayer.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(Exception e) {
    // Gérer les erreurs Supabase
    if (e.toString().contains('Invalid login credentials')) {
      return AppLocalizations.of(context)!.get('wrong_password');
    } else if (e.toString().contains('User already registered')) {
      return AppLocalizations.of(context)!.get('email_already_used');
    } else if (e.toString().contains('Email not confirmed')) {
      return AppLocalizations.of(context)!.get('email_sent');
    } else {
      return 'Erreur: ${e.toString()}';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
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
                      
                      // Logo et titre
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(context).primaryColor.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'TicketScan',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLogin ? 'Connectez-vous pour continuer' : 'Créez votre compte',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Champ email
                      CustomTextField(
                        controller: _emailController,
                        label: AppLocalizations.of(context)!.get('email'),
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.get('invalid_email');
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return AppLocalizations.of(context)!.get('invalid_email');
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Champ mot de passe
                      CustomTextField(
                        controller: _passwordController,
                        label: AppLocalizations.of(context)!.get('password'),
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.get('weak_password');
                          }
                          if (value.length < 6) {
                            return AppLocalizations.of(context)!.get('weak_password');
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Bouton de connexion/inscription
                      PrimaryButton(
                        text: _isLogin ? AppLocalizations.of(context)!.get('sign_in') : AppLocalizations.of(context)!.get('sign_up'),
                        onPressed: _submit,
                        isLoading: _isLoading,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Lien pour changer de mode
                      Center(
                        child: TextButton(
                          onPressed: _toggleAuthMode,
                          child: Text.rich(
                            TextSpan(
                              text: _isLogin ? AppLocalizations.of(context)!.get('no_account') : AppLocalizations.of(context)!.get('already_account'),
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                TextSpan(
                                  text: _isLogin ? AppLocalizations.of(context)!.get('sign_up') : AppLocalizations.of(context)!.get('sign_in'),
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Bouton mot de passe oublié (uniquement en mode connexion)
                      if (_isLogin) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: _resetPassword,
                            child: Text(
                              AppLocalizations.of(context)!.get('forgot_password'),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showErrorSnackBar(AppLocalizations.of(context)!.get('invalid_email') + ' ' + AppLocalizations.of(context)!.get('email').toLowerCase());
      return;
    }

    try {
      // await FirebaseService.resetPassword(email);
      await SupabaseService.resetPassword(email);
      _showErrorSnackBar(AppLocalizations.of(context)!.get('email_sent'));
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.of(context)!.get('generic_error'));
    }
  }
}
