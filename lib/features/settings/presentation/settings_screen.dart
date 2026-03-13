import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/settings_notifier.dart';
import '../../../features/settings/domain/validators/settings_validator.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _churchNameCtrl;
  final _validator = SettingsValidator();

  @override
  void initState() {
    super.initState();
    _churchNameCtrl = TextEditingController(
        text: context.read<SettingsNotifier>().settings.churchName);
  }

  @override
  void dispose() {
    _churchNameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<SettingsNotifier>().setChurchName(_churchNameCtrl.text);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas.')));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<SettingsNotifier>().settings.isDarkMode;
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Igreja', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _churchNameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nome da Igreja',
                    border: OutlineInputBorder()),
                validator: (v) => _validator.validateChurchName(v ?? ''),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                ),
              ),
              const SizedBox(height: 32),
              Text('Aparência',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Tema escuro'),
                value: isDark,
                onChanged: (_) =>
                    context.read<SettingsNotifier>().toggleDarkMode(),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
