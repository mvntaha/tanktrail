import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_tokens.dart';
import '../data/auth_repository.dart';

/// Email + password only. Accounts are created by the owner (seed script), so
/// there is no sign-up or password-reset flow in the app.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(email: _email.text, password: _password.text);
      // No navigation here: the router reacts to the new session.
    } catch (e) {
      if (mounted) setState(() => _error = signInErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.local_gas_station_rounded, size: 56, color: t.primary),
                      const SizedBox(height: 16),
                      Text(
                        'TankTrail',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: t.foreground),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in with the account the owner gave you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: t.mutedForeground),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _email,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        style: const TextStyle(fontSize: 17),
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        enabled: !_busy,
                        obscureText: !_showPassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        style: const TextStyle(fontSize: 17),
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            tooltip: _showPassword ? 'Hide password' : 'Show password',
                            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _showPassword = !_showPassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!, style: TextStyle(color: t.destructive, fontSize: 15)),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _submit();
                              },
                        child: _busy
                            ? SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: t.primaryForeground),
                              )
                            : const Text('Sign in'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Forgot your password? Ask the owner to reset it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: t.mutedForeground),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
