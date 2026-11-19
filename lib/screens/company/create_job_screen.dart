import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';

const _contractTypes = [
  'Tempo indeterminato',
  'Tempo determinato',
  'Part-time',
  'Stage / Tirocinio',
  'Apprendistato',
  'Freelance',
];

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  String? _contractType;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<Session>().api.createJob(
        title: _title.text.trim(),
        description: _description.text.trim(),
        location: trimmedOrNull(_location.text),
        contractType: _contractType,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuovo annuncio')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Titolo *',
                hintText: 'Es. Sviluppatore Flutter junior',
              ),
              maxLength: 120,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (v) => requiredField(v, 'il titolo'),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Descrizione *',
                hintText: 'Mansioni, requisiti, cosa offrite…',
                alignLabelWithHint: true,
              ),
              minLines: 5,
              maxLines: 12,
              maxLength: 5000,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => requiredField(v, 'la descrizione'),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Sede',
                hintText: 'Es. Napoli, Remoto…',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _contractType,
              decoration: const InputDecoration(labelText: 'Tipo di contratto'),
              items: [
                for (final type in _contractTypes)
                  DropdownMenuItem(value: type, child: Text(type)),
              ],
              onChanged: (value) => setState(() => _contractType = value),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _saving ? null : _publish,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Pubblica annuncio'),
            ),
          ],
        ),
      ),
    );
  }
}
