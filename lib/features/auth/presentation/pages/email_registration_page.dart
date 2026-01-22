import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../di/injection_container.dart';
import '../bloc/email_registration_bloc.dart';
import '../bloc/email_registration_event.dart';
import '../bloc/email_registration_state.dart';

/// Email registration page with multi-step flow
class EmailRegistrationPage extends StatelessWidget {
  const EmailRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EmailRegistrationBloc>(),
      child: const _EmailRegistrationView(),
    );
  }
}

class _EmailRegistrationView extends StatefulWidget {
  const _EmailRegistrationView();

  @override
  State<_EmailRegistrationView> createState() => _EmailRegistrationViewState();
}

class _EmailRegistrationViewState extends State<_EmailRegistrationView> {
  final _pageController = PageController();
  final _emailController = TextEditingController(text: 'hj4633311@gmail.com');
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Whgywnssla1');
  final _confirmPasswordController = TextEditingController(text: 'Whgywnssla1');

  int _currentStep = 0;
  String _email = '';
  String _code = '';

  // Terms agreement
  bool _overage = false;
  bool _agree = false;
  bool _collect = false;
  bool _thirdparty = false;
  bool _advertise = false;

  bool get _allRequiredAgreed =>
      _overage && _agree && _collect && _thirdparty;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep > 0) {
              _goToStep(_currentStep - 1);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<EmailRegistrationBloc, EmailRegistrationState>(
          listener: (context, state) {
          switch (state) {
            case EmailAvailable(:final email):
              _email = email;
              // Auto-send verification code
              context
                  .read<EmailRegistrationBloc>()
                  .add(VerificationCodeRequested(email: email));
            case EmailNotAvailable():
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email already registered'),
                  backgroundColor: Colors.red,
                ),
              );
            case VerificationCodeSent():
              _goToStep(1);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification code sent')),
              );
            case CodeVerified(:final code):
              _code = code;
              _goToStep(2);
            case EmailRegistrationSuccess():
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Registration successful! Please login.'),
                  backgroundColor: Colors.green,
                ),
              );
              context.go('/login');
            case EmailRegistrationError(:final message):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.red,
                ),
              );
            default:
              break;
          }
        },
        builder: (context, state) {
          final isLoading = state is EmailRegistrationLoading;

          return Column(
            children: [
              // Step indicator
              _buildStepIndicator(),
              // Page content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildEmailStep(isLoading),
                    _buildCodeStep(isLoading),
                    _buildPasswordStep(isLoading),
                    _buildTermsStep(isLoading),
                  ],
                ),
              ),
            ],
          );
        },
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmailStep(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your email',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'We will send a verification code to this email.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'example@email.com',
              border: OutlineInputBorder(),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      final email = _emailController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter email')),
                        );
                        return;
                      }
                      context
                          .read<EmailRegistrationBloc>()
                          .add(EmailCheckRequested(email: email));
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeStep(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter verification code',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'A code was sent to $_email',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Verification Code',
              hintText: '000000',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: isLoading
                ? null
                : () {
                    context
                        .read<EmailRegistrationBloc>()
                        .add(VerificationCodeRequested(email: _email));
                  },
            child: const Text('Resend Code'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      final code = _codeController.text.trim();
                      if (code.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter code')),
                        );
                        return;
                      }
                      context.read<EmailRegistrationBloc>().add(
                            CodeVerificationRequested(
                              email: _email,
                              code: code,
                            ),
                          );
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep(bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create password',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a secure password for your account.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm Password',
              border: OutlineInputBorder(),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      final password = _passwordController.text;
                      final confirm = _confirmPasswordController.text;
                      if (password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter password')),
                        );
                        return;
                      }
                      if (password != confirm) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Passwords do not match')),
                        );
                        return;
                      }
                      _goToStep(3);
                    },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsStep(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Terms of Service',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please agree to the following terms.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          // Agree all
          CheckboxListTile(
            title: const Text('Agree to all'),
            value: _overage && _agree && _collect && _thirdparty && _advertise,
            onChanged: (value) {
              setState(() {
                _overage = value ?? false;
                _agree = value ?? false;
                _collect = value ?? false;
                _thirdparty = value ?? false;
                _advertise = value ?? false;
              });
            },
          ),
          const Divider(),
          CheckboxListTile(
            title: const Text('[Required] I am over 14 years old'),
            value: _overage,
            onChanged: (v) => setState(() => _overage = v ?? false),
          ),
          CheckboxListTile(
            title: const Text('[Required] Terms of Service'),
            value: _agree,
            onChanged: (v) => setState(() => _agree = v ?? false),
          ),
          CheckboxListTile(
            title: const Text('[Required] Privacy Policy'),
            value: _collect,
            onChanged: (v) => setState(() => _collect = v ?? false),
          ),
          CheckboxListTile(
            title: const Text('[Required] Third-party Information Sharing'),
            value: _thirdparty,
            onChanged: (v) => setState(() => _thirdparty = v ?? false),
          ),
          CheckboxListTile(
            title: const Text('[Optional] Marketing Consent'),
            value: _advertise,
            onChanged: (v) => setState(() => _advertise = v ?? false),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading || !_allRequiredAgreed
                  ? null
                  : () {
                      context.read<EmailRegistrationBloc>().add(
                            EmailRegistrationSubmitted(
                              email: _email,
                              password: _passwordController.text,
                              code: _code,
                              overage: _overage,
                              agree: _agree,
                              collect: _collect,
                              thirdparty: _thirdparty,
                              advertise: _advertise,
                            ),
                          );
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign Up'),
            ),
          ),
        ],
      ),
    );
  }
}
