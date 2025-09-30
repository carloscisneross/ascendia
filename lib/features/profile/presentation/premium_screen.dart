import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/providers.dart';
import '../../core/constants.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Offerings? _offerings;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final premiumService = ref.read(premiumServiceProvider);
      final offerings = await premiumService.getOfferings();
      
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load premium options. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _purchasePackage(Package package) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final premiumService = ref.read(premiumServiceProvider);
      final customerInfo = await premiumService.purchasePackage(package);
      
      // Check if purchase was successful
      if (customerInfo.entitlements.active.containsKey(AppConstants.premiumEntitlementId)) {
        // Update local providers
        ref.invalidate(premiumStatusProvider);
        
        // Return success result
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = 'Purchase was not completed. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final premiumService = ref.read(premiumServiceProvider);
      final customerInfo = await premiumService.restorePurchases();
      
      if (customerInfo.entitlements.active.containsKey(AppConstants.premiumEntitlementId)) {
        // Update local providers
        ref.invalidate(premiumStatusProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Premium subscription restored successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = 'No premium subscription found to restore.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to restore purchases. Please try again.';
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is PurchasesErrorCode) {
      switch (error) {
        case PurchasesErrorCode.purchaseCancelledError:
          return 'Purchase was cancelled.';
        case PurchasesErrorCode.paymentPendingError:
          return 'Payment is pending. Please wait for confirmation.';
        case PurchasesErrorCode.networkError:
          return 'Network error. Please check your connection.';
        default:
          return 'Purchase failed. Please try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Premium'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.standardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            
            // Header
            Text(
              'Ascendia Premium',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock exclusive avatars and premium features',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // Premium Features
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.largePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Benefits',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeature(
                      context,
                      Icons.person,
                      'Exclusive Avatars',
                      'Access to premium avatar collection with unique designs',
                    ),
                    const SizedBox(height: 16),
                    _buildFeature(
                      context,
                      Icons.star,
                      'Premium Medals',
                      'Unlock special medal designs and achievements',
                    ),
                    const SizedBox(height: 16),
                    _buildFeature(
                      context,
                      Icons.support,
                      'Priority Support',
                      'Get priority customer support and feature requests',
                    ),
                    const SizedBox(height: 16),
                    _buildFeature(
                      context,
                      Icons.update,
                      'Early Access',
                      'Be the first to try new features and updates',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Offerings
            if (_isLoading && _offerings == null)
              const Center(child: CircularProgressIndicator())
            else if (_offerings != null) ...[
              // Package Options
              ..._offerings!.current?.availablePackages.map((package) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    child: InkWell(
                      onTap: _isLoading ? null : () => _purchasePackage(package),
                      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.largePadding),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    package.storeProduct.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    package.storeProduct.description,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              package.storeProduct.priceString,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
            
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
            
            // Restore Purchases Button
            if (_offerings != null)
              TextButton(
                onPressed: _isLoading ? null : _restorePurchases,
                child: const Text('Restore Purchases'),
              ),
            
            const SizedBox(height: 16),
            
            // Loading Indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(BuildContext context, IconData icon, String title, String description) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}