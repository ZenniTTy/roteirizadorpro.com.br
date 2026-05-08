import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rp_button.dart';
import '../../../core/widgets/rp_ghost_button.dart';
import '../../../core/widgets/rp_input.dart';
import '../../../core/widgets/rp_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _registerTapRecognizer = TapGestureRecognizer();
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _registerTapRecognizer.onTap = () => context.go('/register');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _registerTapRecognizer.dispose();
    super.dispose();
  }

  void _showStub(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final minHeight = mediaQuery.size.height - mediaQuery.padding.vertical - 56;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Column(
                    children: [
                      RpLogo(size: 72),
                      SizedBox(height: 16),
                      Text(
                        'Roteirizador Pro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Entregue mais. Chegue em casa cedo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  RpInput(
                    label: 'E-mail',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    placeholder: 'seu@email.com',
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  RpInput(
                    label: 'Senha',
                    controller: _passwordController,
                    placeholder: '••••••••',
                    obscureText: !_showPassword,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    suffix: GestureDetector(
                      onTap: () =>
                          setState(() => _showPassword = !_showPassword),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _showStub('Recuperação de senha em breve.'),
                    child: const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Text(
                          'Esqueci minha senha',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  RpButton(
                    label: 'Entrar',
                    onPressed: () =>
                        _showStub('Login: API ainda não está conectada.'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 1, color: AppColors.border),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'ou',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(height: 1, color: AppColors.border),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  RpGhostButton(
                    label: 'Continuar com Google',
                    icon: const _GoogleGlyph(),
                    onPressed: () =>
                        _showStub('Login com Google será habilitado em M2.'),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 8),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                        children: [
                          const TextSpan(text: 'Não tem conta? '),
                          TextSpan(
                            text: 'Cadastre-se',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: _registerTapRecognizer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.g_mobiledata, size: 26, color: Color(0xFF4285F4));
  }
}
