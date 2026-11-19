import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';

class ApplicationDetailScreen extends StatefulWidget {
  const ApplicationDetailScreen({super.key, required this.application});

  final JobApplication application;

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  bool _opening = false;

  Future<void> _openCv() async {
    setState(() => _opening = true);
    try {
      final file = await context.read<Session>().api.downloadCv(
        widget.application,
      );
      final result = await OpenFilex.open(file.path, type: 'application/pdf');
      if (!mounted) return;
      if (result.type != ResultType.done) {
        showMessage(
          context,
          'Impossibile aprire il PDF: ${result.message}',
          error: true,
        );
      }
    } on ApiException catch (e) {
      if (mounted) showMessage(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final application = widget.application;

    return Scaffold(
      appBar: AppBar(title: const Text('Candidato')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  '${application.firstName.characters.first}${application.lastName.characters.first}'
                      .toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.fullName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Candidatura per ${application.jobTitle}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Nome',
                  value: application.firstName,
                ),
                _InfoRow(
                  icon: Icons.person_outline,
                  label: 'Cognome',
                  value: application.lastName,
                ),
                _InfoRow(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  value: application.email,
                ),
                if (application.phone != null)
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Telefono',
                    value: application.phone!,
                  ),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Ricevuta il',
                  value: formatDate(application.createdAt),
                ),
              ],
            ),
          ),
          if (application.message != null) ...[
            const SizedBox(height: 24),
            Text(
              'Messaggio',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              application.message!,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Curriculum',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Icon(
                Icons.picture_as_pdf,
                color: theme.colorScheme.error,
              ),
              title: Text(application.cvFilename),
              subtitle: const Text('Tocca per aprire'),
              trailing: _opening
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.open_in_new),
              onTap: _opening ? null : _openCv,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _opening ? null : _openCv,
            icon: const Icon(Icons.description_outlined),
            label: const Text('Apri curriculum'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(label, style: theme.textTheme.bodySmall),
      subtitle: SelectableText(value, style: theme.textTheme.bodyLarge),
    );
  }
}
