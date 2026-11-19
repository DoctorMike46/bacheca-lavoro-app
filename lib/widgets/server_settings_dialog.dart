import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../state/session.dart';
import 'common.dart';

Future<void> showServerSettings(BuildContext context) =>
    showDialog(context: context, builder: (_) => const _ServerSettingsDialog());

class _ServerSettingsDialog extends StatefulWidget {
  const _ServerSettingsDialog();

  @override
  State<_ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<_ServerSettingsDialog> {
  late final _controller = TextEditingController(
    text: context.read<Session>().api.baseUrl,
  );
  bool _testing = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final session = context.read<Session>();
    final previous = session.api.baseUrl;
    setState(() {
      _testing = true;
      _error = null;
    });

    await session.setServerUrl(_controller.text);
    try {
      await session.api.ping();
      if (!mounted) return;
      Navigator.pop(context);
      showMessage(context, 'Connesso a ${session.api.baseUrl}');
    } on ApiException catch (e) {
      await session.setServerUrl(previous);
      setState(() {
        _testing = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Indirizzo del server'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usa l\'indirizzo stampato dal server all\'avvio, ad esempio http://192.168.1.10:8080',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'URL',
              errorText: _error,
              errorMaxLines: 3,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _controller.text = Session.defaultServerUrl,
          child: const Text('Predefinito'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: _testing ? null : _save,
          child: _testing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salva'),
        ),
      ],
    );
  }
}
