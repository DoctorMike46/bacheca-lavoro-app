import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';

const _maxCvBytes = 10 * 1024 * 1024;

class ApplyScreen extends StatefulWidget {
  const ApplyScreen({super.key, required this.job});

  final Job job;

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();

  String? _cvName;
  List<int>? _cvBytes;
  bool _cvMissing = false;
  bool _sending = false;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _message,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCv() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _maxCvBytes) {
      showMessage(
        context,
        'Il curriculum non può superare i 10 MB',
        error: true,
      );
      return;
    }
    setState(() {
      _cvName = file.name;
      _cvBytes = bytes;
      _cvMissing = false;
    });
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    setState(() => _cvMissing = _cvBytes == null);
    if (!formValid || _cvBytes == null) return;

    setState(() => _sending = true);
    try {
      await context.read<Session>().api.apply(
        widget.job.id,
        ApplicationDraft(
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          email: _email.text.trim(),
          phone: trimmedOrNull(_phone.text),
          message: trimmedOrNull(_message.text),
          cvFilename: _cvName!,
          cvBytes: _cvBytes!,
        ),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ApplicationSentScreen(job: widget.job),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Candidatura')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              widget.job.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(widget.job.companyName, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            TextFormField(
              controller: _firstName,
              decoration: const InputDecoration(labelText: 'Nome *'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) => requiredField(v, 'il nome'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastName,
              decoration: const InputDecoration(labelText: 'Cognome *'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: (v) => requiredField(v, 'il cognome'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              validator: emailField,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Telefono'),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _message,
              decoration: const InputDecoration(
                labelText: 'Messaggio di presentazione',
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),
            _CvPickerTile(
              fileName: _cvName,
              showError: _cvMissing,
              onTap: _sending ? null : _pickCv,
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Invia candidatura'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CvPickerTile extends StatelessWidget {
  const _CvPickerTile({
    required this.fileName,
    required this.showError,
    required this.onTap,
  });

  final String? fileName;
  final bool showError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selected = fileName != null;
    final borderColor = showError
        ? scheme.error
        : (selected ? scheme.primary : scheme.outlineVariant);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: selected
              ? scheme.primaryContainer.withValues(alpha: 0.4)
              : scheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: borderColor),
          ),
          child: ListTile(
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: Icon(
              selected ? Icons.picture_as_pdf : Icons.upload_file_outlined,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            title: Text(selected ? fileName! : 'Allega il curriculum (PDF) *'),
            subtitle: Text(
              selected ? 'Tocca per sostituirlo' : 'Massimo 10 MB',
            ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(
              'Allega il curriculum',
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class ApplicationSentScreen extends StatelessWidget {
  const ApplicationSentScreen({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.check_rounded,
                size: 52,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Candidatura inviata!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'La tua candidatura per "${job.title}" è stata inviata a ${job.companyName}.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Torna alla bacheca'),
            ),
          ],
        ),
      ),
    );
  }
}
