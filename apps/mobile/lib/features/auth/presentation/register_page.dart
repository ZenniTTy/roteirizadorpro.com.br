import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/rp_button.dart';
import '../../../core/widgets/rp_input.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _termsTapRecognizer = TapGestureRecognizer();
  final _privacyTapRecognizer = TapGestureRecognizer();
  final _loginTapRecognizer = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _termsTapRecognizer.onTap = () => _showStub('Termos: tela em breve.');
    _privacyTapRecognizer.onTap =
        () => _showStub('Política de privacidade: tela em breve.');
    _loginTapRecognizer.onTap = () => context.go('/login');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _termsTapRecognizer.dispose();
    _privacyTapRecognizer.dispose();
    _loginTapRecognizer.dispose();
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
    final minHeight =
        mediaQuery.size.height - mediaQuery.padding.vertical - 56 - 56;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        titleSpacing: 4,
        leading: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 22,
          color: AppColors.text,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
        title: const Text(
          'Criar conta',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      'Comece a otimizar suas rotas em menos de 1 minuto.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  RpInput(
                    label: 'Nome completo',
                    controller: _nameController,
                    placeholder: 'João Silva',
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
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
                    label: 'Telefone',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    placeholder: '11 99999-0000',
                    autofillHints: const [AutofillHints.telephoneNumber],
                    textInputAction: TextInputAction.next,
                    prefix: const Text('+55'),
                  ),
                  const SizedBox(height: 14),
                  RpInput(
                    label: 'Senha',
                    controller: _passwordController,
                    placeholder: 'Mínimo 8 caracteres',
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 24),
                  RpButton(
                    label: 'Criar conta',
                    onPressed: () =>
                        _showStub('Cadastro: API ainda não está conectada.'),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'Ao criar conta você aceita nossos\n'),
                        TextSpan(
                          text: 'Termos',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: _termsTapRecognizer,
                        ),
                        const TextSpan(text: ' e '),
                        TextSpan(
                          text: 'Política de privacidade',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          recognizer: _privacyTapRecognizer,
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                        children: [
                          const TextSpan(text: 'Já tem conta? '),
                          TextSpan(
                            text: 'Entrar',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            recognizer: _loginTapRecognizer,
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
