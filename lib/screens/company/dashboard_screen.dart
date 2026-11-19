import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';
import 'create_job_screen.dart';
import 'job_applications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Job>? _jobs;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final jobs = await context.read<Session>().api.myJobs();
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isUnauthorized) {
        return _signOut(message: 'Sessione scaduta, accedi di nuovo.');
      }
      setState(() => _error = e.message);
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Esci'),
        content: const Text('Vuoi uscire dall\'area riservata?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Esci'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _signOut(message: 'Sei uscito dall\'area riservata.');
    }
  }

  Future<void> _signOut({required String message}) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await context.read<Session>().logout();
    navigator.popUntil((route) => route.isFirst);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _createJob() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateJobScreen()),
    );
    if (created != true || !mounted) return;
    showMessage(context, 'Annuncio pubblicato nella bacheca');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final company = context.watch<Session>().company;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Area riservata'),
        actions: [
          IconButton(
            tooltip: 'Esci',
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createJob,
        icon: const Icon(Icons.add),
        label: const Text('Nuovo annuncio'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (company != null) _CompanyHeader(company: company),
          Expanded(child: _buildJobs()),
        ],
      ),
    );
  }

  Widget _buildJobs() {
    final jobs = _jobs;
    if (jobs == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (jobs == null) {
      return RefreshableBody(
        onRefresh: _load,
        child: MessageView(
          icon: Icons.cloud_off_outlined,
          title: 'Impossibile caricare i tuoi annunci',
          message: _error,
          actionLabel: 'Riprova',
          onAction: _load,
        ),
      );
    }

    if (jobs.isEmpty) {
      return RefreshableBody(
        onRefresh: _load,
        child: const MessageView(
          icon: Icons.post_add_outlined,
          title: 'Non hai ancora pubblicato annunci',
          message: 'Tocca "Nuovo annuncio" per crearne uno.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: jobs.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              'I tuoi annunci',
              style: Theme.of(context).textTheme.labelLarge,
            );
          }
          final job = jobs[index - 1];
          return JobCard(
            title: job.title,
            subtitle: 'Pubblicato il ${formatDate(job.createdAt)}',
            chips: [
              InfoChip(
                icon: Icons.people_outline,
                label: job.applicationsCount == 1
                    ? '1 candidatura'
                    : '${job.applicationsCount} candidature',
              ),
            ],
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobApplicationsScreen(job: job),
                ),
              );
              _load();
            },
          );
        },
      ),
    );
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({required this.company});

  final Company company;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            child: Text(company.name.characters.first.toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(company.email, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
