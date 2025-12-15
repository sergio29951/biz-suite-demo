import 'dart:ui';
import 'package:flutter/material.dart';

class SignInView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onSignup;

  const SignInView({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
    required this.onSignup,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Background hero
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        cs.surface,
                        cs.surfaceContainerHighest,
                        cs.surface,
                      ]
                    : [
                        cs.primaryContainer,
                        cs.surface,
                        cs.tertiaryContainer,
                      ],
              ),
            ),
          ),
        ),

        // Blobs
        Positioned(
          top: -120,
          right: -120,
          child: _Blob(color: cs.primary.withOpacity(.25)),
        ),
        Positioned(
          bottom: -140,
          left: -140,
          child: _Blob(color: cs.tertiary.withOpacity(.18)),
        ),

        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Brand
                        Column(
                          children: [
                            _Logo(),
                            const SizedBox(height: 12),
                            Text(
                              'Biz Suite',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Accedi alla tua area di lavoro',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: cs.onSurface.withOpacity(.65),
                                  ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Inserisci l\'email'
                              : null,
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Inserisci la password'
                              : null,
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          height: 48,
                          child: FilledButton(
                            onPressed: isLoading ? null : onSubmit,
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Accedi'),
                          ),
                        ),

                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: isLoading ? null : onSignup,
                          child: const Text('Crea account'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ---------- UI PIECES ---------- */

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? cs.surface : Colors.white)
                .withOpacity(isDark ? .35 : .65),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.onSurface.withOpacity(.12)),
            boxShadow: [
              BoxShadow(
                blurRadius: 30,
                color: Colors.black.withOpacity(.15),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  const _Blob({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, cs.primary.withOpacity(.6)],
        ),
      ),
      child: const Icon(
        Icons.grid_view_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
