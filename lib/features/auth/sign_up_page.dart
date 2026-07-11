// lib/features/auth/sign_up_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_notifier.dart';
import 'auth_page.dart';
import 'confirm_email_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();

  String? _selectedCountry; // país opcional
  String _selectedCurrency = 'EUR';
  String _countryDialCode = ''; // vazio até escolher país
  bool _notificationsEnabled = true;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  int _passwordStrength = 0; // 0–4

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength(String value) {
    setState(() {
      _passwordStrength = _calculatePasswordStrength(value);
    });
  }

  int _calculatePasswordStrength(String password) {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password)) score++;
    return score.clamp(0, 4);
  }

  Color _strengthColor(ThemeData theme) {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return theme.colorScheme.error;
      case 2:
        return Colors.orange;
      case 3:
        return theme.colorScheme.secondary;
      case 4:
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.outline;
    }
  }

  String _strengthLabel() {
    switch (_passwordStrength) {
      case 0:
      case 1:
        return 'Fraca';
      case 2:
        return 'Média';
      case 3:
        return 'Forte';
      case 4:
        return 'Muito forte';
      default:
        return '';
    }
  }

  void _onCountryChanged(String? value) {
    setState(() {
      _selectedCountry = value;

      switch (value) {
        case 'Portugal':
          _countryDialCode = '+351';
          break;
        case 'Espanha':
          _countryDialCode = '+34';
          break;
        case 'França':
          _countryDialCode = '+33';
          break;
        case 'Alemanha':
          _countryDialCode = '+49';
          break;
        case 'Reino Unido':
          _countryDialCode = '+44';
          break;
        case 'Estados Unidos':
          _countryDialCode = '+1';
          break;
        case 'Brasil':
          _countryDialCode = '+55';
          break;
        default:
          _countryDialCode = '';
      }
    });
  }

  Future<void> _submit() async {
    final auth = context.read<AuthNotifier>();
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    if (auth.state.isLoading) return;

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final fullName = _nameController.text.trim();
    final mobileLocal = _mobileController.text.trim();

    final String? mobile = mobileLocal.isEmpty || _countryDialCode.isEmpty
        ? null
        : '$_countryDialCode $mobileLocal';

    try {
      await auth.signUpWithEmail(
        email: email,
        password: _passwordController.text,
        fullName: fullName.isEmpty ? null : fullName,
        username: username,
        country: _selectedCountry,
        currency: _selectedCurrency,
        mobileNumber: mobile,
        notificationsEnabled: _notificationsEnabled,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ConfirmEmailPage()),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthNotifier>().state;
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Secção conta
                Text(
                  'Conta',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // 1) Nome do utilizador
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do utilizador',
                    hintText: 'Como queres ser identificado na app',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  maxLength: 20,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) {
                      return 'Indica o teu nome de utilizador';
                    }
                    if (v.length < 3) {
                      return 'Mínimo 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // 2) Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'exemplo@dominio.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) {
                      return 'Indica um email';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // 3) Password
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: _updatePasswordStrength,
                  validator: (value) {
                    final v = value ?? '';
                    if (v.isEmpty) {
                      return 'Indica uma password';
                    }
                    if (v.length < 8) {
                      return 'A password deve ter pelo menos 8 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // 4) Confirmar password + dica + medidor
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirmar password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirma a password';
                    }
                    if (value != _passwordController.text) {
                      return 'As passwords não coincidem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Dica: usa pelo menos 8 caracteres com letras maiúsculas, '
                  'minúsculas, números e símbolos para uma password mais forte.',
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        minHeight: 6,
                        value: _passwordStrength / 4.0,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _strengthColor(theme),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _strengthLabel(),
                      style: textTheme.bodySmall?.copyWith(
                        color: _strengthColor(theme),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Secção informação adicional
                Text(
                  'Informação adicional (opcional)',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // 5) Nome completo (opcional)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                // 6) País (opcional)
                DropdownButtonFormField<String>(
                  initialValue: _selectedCountry,
                  decoration: const InputDecoration(labelText: 'País'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Portugal',
                      child: Text('Portugal'),
                    ),
                    DropdownMenuItem(value: 'Espanha', child: Text('Espanha')),
                    DropdownMenuItem(value: 'França', child: Text('França')),
                    DropdownMenuItem(
                      value: 'Alemanha',
                      child: Text('Alemanha'),
                    ),
                    DropdownMenuItem(
                      value: 'Reino Unido',
                      child: Text('Reino Unido'),
                    ),
                    DropdownMenuItem(
                      value: 'Estados Unidos',
                      child: Text('Estados Unidos'),
                    ),
                    DropdownMenuItem(value: 'Brasil', child: Text('Brasil')),
                    DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                  ],
                  onChanged: _onCountryChanged,
                ),
                const SizedBox(height: 12),

                // 7) Telemóvel (opcional, com indicativo)
                TextFormField(
                  controller: _mobileController,
                  decoration: InputDecoration(
                    labelText: 'Telemóvel',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    prefixText: _countryDialCode.isNotEmpty
                        ? '$_countryDialCode '
                        : null,
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),

                // 8) Moeda (preselecionada)
                DropdownButtonFormField<String>(
                  initialValue: _selectedCurrency,
                  decoration: const InputDecoration(labelText: 'Moeda'),
                  items: const [
                    DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                    DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                    DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedCurrency = value);
                  },
                ),
                const SizedBox(height: 12),

                // Notificações
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ativar notificações'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const Text('Criar conta'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const AuthPage()),
                          );
                        },
                  child: const Text('Já tens conta? Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
