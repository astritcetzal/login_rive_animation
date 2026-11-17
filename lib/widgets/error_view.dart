import 'package:flutter/material.dart';

/// Pantalla amigable que se muestra cuando una petición a la API falla.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.onRetry, this.message});

  /// Acción que se ejecuta al presionar el botón "Reintentar".
  final VoidCallback onRetry;

  /// Mensaje opcional para dar más contexto al usuario.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '¡Ups! Algo salió mal',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ??
                  'No pudimos cargar la información.\n'
                      'Revisa tu conexión e inténtalo de nuevo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
