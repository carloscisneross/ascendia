import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/constants.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final profileRepo = ref.read(profileRepositoryProvider);
      
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final credential = await authService.signInWithEmailPassword(email, password);
      final uid = credential.user!.uid;
      
      // Ensure profile exists with basic info
      await profileRepo.ensureProfile(
        uid, 
        username: email.split('@').first,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/feed');
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final profileRepo = ref.read(profileRepositoryProvider);
      
      final credential = await authService.signInAnonymously();
      final uid = credential.user!.uid;
      
      // Create anonymous profile
      await profileRepo.ensureProfile(uid);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/profileSetup');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to sign in anonymously. Please try again.';
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('user-not-found')) {
      return 'No account found with this email. Please sign up first.';
    } else if (error.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else if (error.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    } else {
      return 'Sign in failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Ascendia'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.standardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              
              // Header
              Text(
                'Sign In',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Continue your streak journey',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Email Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.standardPadding),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email address',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Password Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.standardPadding),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Error Message
              if (_errorMessage != null)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.standardPadding),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              if (_errorMessage != null) const SizedBox(height: 16),
              
              // Sign In Button
              SizedBox(
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sign Up Link
              TextButton(
                onPressed: _isLoading ? null : () {
                  Navigator.of(context).pushNamed('/signup');
                },
                child: const Text('Don\'t have an account? Sign up'),
              ),
              
              const SizedBox(height: 24),
              
              // Divider
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Continue as Guest Button
              SizedBox(
                height: AppConstants.buttonHeight,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _signInAnonymously,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                    ),
                  ),
                  child: const Text('Continue as Guest'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
