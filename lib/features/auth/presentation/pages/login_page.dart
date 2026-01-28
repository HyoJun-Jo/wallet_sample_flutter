import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/entities/auth_entities.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../di/injection_container.dart';
import '../../../../shared/wallet/domain/usecases/check_wallet_usecase.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'cho5652@gmail.com');
  final _passwordController = TextEditingController(text: 'Whgywnssla1!');
  bool _obscurePassword = true;
  bool _autoLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<LoginBloc>().add(LoginWithEmailRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            autoLogin: _autoLogin,
          ));
    }
  }

  void _onSnsLogin(LoginType loginType) {
    context.read<LoginBloc>().add(SnsSignInRequested(
          loginType: loginType,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SafeArea(
        child: BlocConsumer<LoginBloc, LoginState>(
          listener: (context, state) async {
            if (state is LoginAuthenticated) {
              // Check wallet and navigate
              final hasWallet = await sl<CheckWalletUseCase>()(NoParams());
              if (context.mounted) {
                context.go(hasWallet ? '/main' : '/wallet/create');
              }
            } else if (state is SnsRegistrationRequired) {
              context.go('/register/sns', extra: {
                'email': state.email,
                'sixcode': state.sixcode,
                'loginType': state.loginType,
                'timeout': state.timeout,
              });
            } else if (state is LoginError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    const Icon(
                      Icons.account_balance_wallet,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Wallet Base',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 48),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _autoLogin,
                              onChanged: (value) {
                                setState(() {
                                  _autoLogin = value ?? false;
                                });
                              },
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _autoLogin = !_autoLogin;
                                });
                              },
                              child: const Text('Auto login'),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.push('/reset-password'),
                          child: const Text('Forgot password?'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: state is LoginLoading ? null : _onEmailLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: state is LoginLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 32),

                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('or'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (Platform.isAndroid) ...[
                      _buildSnsLoginButton(
                        label: 'Login with Google',
                        icon: Icons.g_mobiledata,
                        color: Colors.white,
                        textColor: Colors.black87,
                        onPressed: state is LoginLoading
                            ? null
                            : () => _onSnsLogin(LoginType.google),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (Platform.isIOS) ...[
                      _buildSnsLoginButton(
                        label: 'Login with Apple',
                        icon: Icons.apple,
                        color: Colors.black,
                        textColor: Colors.white,
                        onPressed: state is LoginLoading
                            ? null
                            : () => _onSnsLogin(LoginType.apple),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildSnsLoginButton(
                      label: 'Login with Kakao',
                      icon: Icons.chat_bubble,
                      color: const Color(0xFFFEE500),
                      textColor: Colors.black87,
                      onPressed: state is LoginLoading
                          ? null
                          : () => _onSnsLogin(LoginType.kakao),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: state is LoginLoading
                              ? null
                              : () => context.push('/register/email'),
                          child: const Text('Sign up with Email'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSnsLoginButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
