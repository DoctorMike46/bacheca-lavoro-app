import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';
import '../../widgets/server_settings_dialog.dart';
import '../auth/login_screen.dart';
import '../company/dashboard_screen.dart';
import 'job_detail_screen.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  List<Job>? _jobs;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final jobs = await context.read<Session>().api.listJobs();
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _openCompanyArea() async {
    final session = context.read<Session>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => session.isAuthenticated
            ? const DashboardScreen()
            : const LoginScreen(),
      ),
    );
    _load();
  }

  Future<void> _openSettings() async {
    await showServerSettings(context);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<Session>().isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacheca'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _openCompanyArea,
              icon: Icon(
                isAuthenticated
                    ? Icons.dashboard_outlined
                    : Icons.business_outlined,
              ),
              label: Text(isAuthenticated ? 'Area riservata' : 'Area aziende'),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final jobs = _jobs;
    if (jobs == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (jobs == null) {
      return RefreshableBody(
        onRefresh: _load,
        child: MessageView(
          icon: Icons.cloud_off_outlined,
          title: 'Impossibile caricare gli annunci',
          message: _error,
          actionLabel: 'Riprova',
          onAction: _load,
          secondaryLabel: 'Cambia indirizzo server',
          onSecondary: _openSettings,
        ),
      );
    }

    if (jobs.isEmpty) {
      return RefreshableBody(
        onRefresh: _load,
        child: const MessageView(
          icon: Icons.work_outline,
          title: 'Nessun annuncio pubblicato',
          message: 'Torna più tardi o trascina verso il basso per aggiornare.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: jobs.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              '${jobs.length} ${jobs.length == 1 ? 'annuncio disponibile' : 'annunci disponibili'}',
              style: Theme.of(context).textTheme.labelLarge,
            );
          }
          final job = jobs[index - 1];
          return JobCard(
            title: job.title,
            subtitle: job.companyName,
            chips: [
              if (job.location != null)
                InfoChip(icon: Icons.place_outlined, label: job.location!),
              if (job.contractType != null)
                InfoChip(icon: Icons.badge_outlined, label: job.contractType!),
              InfoChip(
                icon: Icons.calendar_today_outlined,
                label: formatDate(job.createdAt),
              ),
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
            ),
          );
        },
      ),
    );
  }
}
