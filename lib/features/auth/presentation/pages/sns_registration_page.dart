import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/auth_entities.dart';
import '../bloc/sns_registration_bloc.dart';
import '../bloc/sns_registration_event.dart';
import '../bloc/sns_registration_state.dart';

/// SNS Registration page (after code 618 - user not found)
class SnsRegistrationPage extends StatefulWidget {
  final String email;
  final String sixcode;
  final LoginType loginType;
  final int timeout;

  const SnsRegistrationPage({
    super.key,
    required this.email,
    required this.sixcode,
    required this.loginType,
    required this.timeout,
  });

  @override
  State<SnsRegistrationPage> createState() => _SnsRegistrationPageState();
}

class _SnsRegistrationPageState extends State<SnsRegistrationPage> {
  // Terms agreement checkboxes
  bool _allAgree = false;
  bool _overage = false;
  bool _agree = false;
  bool _collect = false;
  bool _thirdparty = false;
  bool _advertise = false;

  bool get _requiredAgreed =>
      _overage && _agree && _collect && _thirdparty;

  void _updateAllAgree() {
    setState(() {
      _allAgree = _overage && _agree && _collect && _thirdparty && _advertise;
    });
  }

  void _onAllAgreeChanged(bool? value) {
    setState(() {
      _allAgree = value ?? false;
      _overage = _allAgree;
      _agree = _allAgree;
      _collect = _allAgree;
      _thirdparty = _allAgree;
      _advertise = _allAgree;
    });
  }

  void _onRegister() {
    if (!_requiredAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to all required terms'),
        ),
      );
      return;
    }

    context.read<SnsRegistrationBloc>().add(
          SnsRegistrationSubmitted(
            email: widget.email,
            code: widget.sixcode,
            loginType: widget.loginType,
            overage: _overage,
            agree: _agree,
            collect: _collect,
            thirdparty: _thirdparty,
            advertise: _advertise,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: BlocListener<SnsRegistrationBloc, SnsRegistrationState>(
          listener: (context, state) {
            if (state is SnsRegistrationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Registration successful! Please login again.'),
                ),
              );
              context.go('/login');
            } else if (state is SnsRegistrationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          child: BlocBuilder<SnsRegistrationBloc, SnsRegistrationState>(
            builder: (context, state) {
              final isLoading = state is SnsRegistrationLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email display
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.email, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Email',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    widget.email,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Terms title
                    const Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // All agree
                    Card(
                      color: _allAgree ? Colors.blue.shade50 : null,
                      child: CheckboxListTile(
                        title: const Text(
                          'Agree to all',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        value: _allAgree,
                        onChanged: isLoading ? null : _onAllAgreeChanged,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Individual terms
                    _buildTermsCheckbox(
                      title: '[Required] I am over 14 years old',
                      value: _overage,
                      onChanged: isLoading
                          ? null
                          : (v) {
                              setState(() => _overage = v ?? false);
                              _updateAllAgree();
                            },
                      required: true,
                    ),
                    _buildTermsCheckbox(
                      title: '[Required] Terms of Service',
                      value: _agree,
                      onChanged: isLoading
                          ? null
                          : (v) {
                              setState(() => _agree = v ?? false);
                              _updateAllAgree();
                            },
                      required: true,
                      onViewDetails: () => _showTermsDialog('Terms of Service'),
                    ),
                    _buildTermsCheckbox(
                      title: '[Required] Privacy Policy',
                      value: _collect,
                      onChanged: isLoading
                          ? null
                          : (v) {
                              setState(() => _collect = v ?? false);
                              _updateAllAgree();
                            },
                      required: true,
                      onViewDetails: () => _showTermsDialog('Privacy Policy'),
                    ),
                    _buildTermsCheckbox(
                      title: '[Required] Third-party Information Sharing',
                      value: _thirdparty,
                      onChanged: isLoading
                          ? null
                          : (v) {
                              setState(() => _thirdparty = v ?? false);
                              _updateAllAgree();
                            },
                      required: true,
                      onViewDetails: () =>
                          _showTermsDialog('Third-party Information Sharing'),
                    ),
                    _buildTermsCheckbox(
                      title: '[Optional] Marketing Consent',
                      value: _advertise,
                      onChanged: isLoading
                          ? null
                          : (v) {
                              setState(() => _advertise = v ?? false);
                              _updateAllAgree();
                            },
                      required: false,
                    ),

                    const SizedBox(height: 32),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            isLoading || !_requiredAgreed ? null : _onRegister,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox({
    required String title,
    required bool value,
    required ValueChanged<bool?>? onChanged,
    required bool required,
    VoidCallback? onViewDetails,
  }) {
    return CheckboxListTile(
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: required ? null : Colors.grey.shade600,
              ),
            ),
          ),
          if (onViewDetails != null)
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 20),
              onPressed: onViewDetails,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showTermsDialog(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const SingleChildScrollView(
          child: Text(
            'Terms content will be displayed here.\n\n'
            'This is a placeholder for the actual terms of service content. '
            'In a production app, this would contain the full legal text.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
