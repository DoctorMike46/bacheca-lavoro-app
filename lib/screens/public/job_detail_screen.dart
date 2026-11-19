import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';
import 'apply_screen.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompany = context.watch<Session>().isAuthenticated;

    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio annuncio')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            job.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.business, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(job.companyName, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (job.location != null)
                InfoChip(icon: Icons.place_outlined, label: job.location!),
              if (job.contractType != null)
                InfoChip(icon: Icons.badge_outlined, label: job.contractType!),
              InfoChip(
                icon: Icons.calendar_today_outlined,
                label: 'Pubblicato il ${formatDate(job.createdAt)}',
              ),
            ],
          ),
          const Divider(height: 40),
          Text(
            'Descrizione',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            job.description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: isCompany
            ? Text(
                'Le aziende non possono candidarsi. Esci dall\'area riservata per inviare una candidatura.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : FilledButton.icon(
                icon: const Icon(Icons.send_outlined),
                label: const Text('Candidati'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ApplyScreen(job: job)),
                ),
              ),
      ),
    );
  }
}
