import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';
import 'application_detail_screen.dart';

class JobApplicationsScreen extends StatefulWidget {
  const JobApplicationsScreen({super.key, required this.job});

  final Job job;

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  List<JobApplication>? _applications;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final applications = await context.read<Session>().api.listApplications(
        widget.job.id,
      );
      if (!mounted) return;
      setState(() {
        _applications = applications;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Candidature')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              widget.job.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    final applications = _applications;
    if (applications == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (applications == null) {
      return RefreshableBody(
        onRefresh: _load,
        child: MessageView(
          icon: Icons.cloud_off_outlined,
          title: 'Impossibile caricare le candidature',
          message: _error,
          actionLabel: 'Riprova',
          onAction: _load,
        ),
      );
    }

    if (applications.isEmpty) {
      return RefreshableBody(
        onRefresh: _load,
        child: const MessageView(
          icon: Icons.inbox_outlined,
          title: 'Nessuna candidatura ricevuta',
          message: 'Le candidature per questo annuncio compariranno qui.',
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: applications.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final application = applications[index];
          return JobCard(
            title: application.fullName,
            subtitle: application.email,
            chips: [
              InfoChip(
                icon: Icons.calendar_today_outlined,
                label: formatDate(application.createdAt),
              ),
              const InfoChip(
                icon: Icons.picture_as_pdf_outlined,
                label: 'CV allegato',
              ),
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ApplicationDetailScreen(application: application),
              ),
            ),
          );
        },
      ),
    );
  }
}
