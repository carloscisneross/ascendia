import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../core/constants.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final profileRepo = ref.read(profileRepositoryProvider);
      
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Check username uniqueness
      final isUsernameAvailable = await profileRepo.isUsernameAvailable(username);
      if (!isUsernameAvailable) {
        setState(() {
          _errorMessage = 'Username is already taken. Please choose another.';
          _isLoading = false;
        });
        return;
      }

      // Create Firebase Auth user
      final credential = await authService.createUserWithEmailAndPassword(email, password);
      final uid = credential.user!.uid;

      // Create user profile in Firestore with defaults
      await profileRepo.ensureProfile(
        uid,
        username: username,
        avatarKey: AppConstants.defaultFreeAvatarPath,
      );

      // Navigate to profile setup
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/profileSetup');
      }
      
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Email is already registered. Try signing in instead.';
    } else if (error.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    } else if (error.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    } else {
      return 'Sign up failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.standardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              
              // Header
              Text(
                'Join Ascendia',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Start your streak journey today',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Username Field
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.standardPadding),
                  child: TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Choose a unique username',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (value.trim().length > 20) {
                        return 'Username must be less than 20 characters';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                        return 'Username can only contain letters, numbers, and underscores';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
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
                      hintText: 'Create a strong password',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
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
              
              // Sign Up Button
              SizedBox(
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
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
                      : const Text('Create Account'),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Back to Login
              TextButton(
                onPressed: _isLoading ? null : () {
                  Navigator.of(context).pop();
                },
                child: const Text('Already have an account? Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}