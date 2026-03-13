// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/volunteer_notifier.dart';
import '../../../features/service_type/domain/enums/service_type.dart';
import '../../../features/service_type/domain/extensions/service_type_extension.dart';
import '../../../features/volunteers/domain/models/volunteer.dart';
import '../../../features/volunteers/domain/services/volunteer_csv_service.dart';
import '../../../features/volunteers/domain/validators/volunteer_validator.dart';

class VolunteersScreen extends StatelessWidget {
  const VolunteersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final volunteers = context.watch<VolunteerNotifier>().volunteers;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voluntários'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar voluntários',
            onPressed: () => _importVolunteers(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar voluntários',
            onPressed: volunteers.isEmpty
                ? null
                : () => _exportVolunteers(context, volunteers),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(context, null),
        icon: const Icon(Icons.person_add),
        label: const Text('Adicionar'),
      ),
      body: volunteers.isEmpty
          ? _EmptyState(onAdd: () => _showDialog(context, null))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: volunteers.length,
              itemBuilder: (ctx, i) {
                final v = volunteers[i];
                return _VolunteerCard(
                  volunteer: v,
                  onEdit: () => _showDialog(ctx, v),
                  onDelete: () => _confirmDelete(ctx, v),
                );
              },
            ),
    );
  }

  Future<void> _exportVolunteers(
      BuildContext context, List<Volunteer> volunteers) async {
    final service = VolunteerCsvService();
    final csv = service.export(volunteers);

    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar voluntários',
        fileName: 'voluntarios.csv',
      );

      if (savePath == null) return;

      await File(savePath).writeAsString(csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voluntários exportados com sucesso.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    }
  }

  Future<void> _importVolunteers(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    final csvStr = String.fromCharCodes(bytes);
    final service = VolunteerCsvService();
    final imported = service.import(csvStr);

    if (imported.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nenhum voluntário válido encontrado no arquivo.')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final notifier = context.read<VolunteerNotifier>();
    int added = 0;
    final skipped = <String>[];

    for (final v in imported) {
      try {
        notifier.add(
          v.name,
          v.serviceTypes,
          age: v.age,
          canServeMultipleTimes: v.canServeMultipleTimes,
          minimumIntervalWeeks: v.minimumIntervalWeeks,
        );
        added++;
      } catch (_) {
        skipped.add(v.name);
      }
    }

    if (context.mounted) {
      final msg = skipped.isEmpty
          ? '$added voluntário(s) importado(s).'
          : '$added importado(s). Ignorados (já existem): ${skipped.join(', ')}.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _showDialog(BuildContext context, Volunteer? existing) {
    showDialog<void>(
      context: context,
      builder: (_) => _VolunteerDialog(existing: existing),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Volunteer v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover voluntário'),
        content: Text('Remover "${v.name}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remover')),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<VolunteerNotifier>().remove(v.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline,
              size: 64, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 16),
          Text('Nenhum voluntário cadastrado',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add),
            label: const Text('Adicionar Voluntário'),
          ),
        ],
      ),
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  final Volunteer volunteer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _VolunteerCard(
      {required this.volunteer, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final typesLabel =
        volunteer.serviceTypes.map((s) => s.label).join(', ');
    final ageLabel =
        volunteer.age != null ? ' • ${volunteer.age} anos' : '';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(volunteer.age != null
            ? '${volunteer.name} (${volunteer.age} anos)'
            : volunteer.name),
        subtitle: Text('$typesLabel$ageLabel'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

// ─── Data class for a single volunteer row in the form ───────────────────────

class _VolunteerRow {
  final TextEditingController nameCtrl;
  final TextEditingController ageCtrl;
  Set<ServiceType> selectedTypes;
  bool canServeMultipleTimes;
  int minimumIntervalWeeks;

  _VolunteerRow({
    String name = '',
    String age = '',
    Set<ServiceType>? selectedTypes,
    this.canServeMultipleTimes = true,
    this.minimumIntervalWeeks = 1,
  })  : nameCtrl = TextEditingController(text: name),
        ageCtrl = TextEditingController(text: age),
        selectedTypes = selectedTypes ?? {};

  void dispose() {
    nameCtrl.dispose();
    ageCtrl.dispose();
  }
}

// ─── Dialog ──────────────────────────────────────────────────────────────────

class _VolunteerDialog extends StatefulWidget {
  final Volunteer? existing;
  const _VolunteerDialog({this.existing});

  @override
  State<_VolunteerDialog> createState() => _VolunteerDialogState();
}

class _VolunteerDialogState extends State<_VolunteerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _validator = VolunteerValidator();
  late List<_VolunteerRow> _rows;
  String? _errorMessage;

  bool get _isEditMode => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final v = widget.existing!;
      _rows = [
        _VolunteerRow(
          name: v.name,
          age: v.age?.toString() ?? '',
          selectedTypes: Set.from(v.serviceTypes),
          canServeMultipleTimes: v.canServeMultipleTimes,
          minimumIntervalWeeks: v.minimumIntervalWeeks,
        )
      ];
    } else {
      _rows = [_VolunteerRow()];
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() => _rows.add(_VolunteerRow()));
  }

  void _removeRow(int index) {
    setState(() {
      _rows[index].dispose();
      _rows.removeAt(index);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    // Validate service types for each row
    for (int i = 0; i < _rows.length; i++) {
      final typeError =
          _validator.validateServiceTypes(_rows[i].selectedTypes.toList());
      if (typeError != null) {
        setState(() => _errorMessage =
            _rows.length > 1 ? 'Voluntário ${i + 1}: $typeError' : typeError);
        return;
      }
    }

    try {
      final notifier = context.read<VolunteerNotifier>();
      if (_isEditMode) {
        final r = _rows.first;
        final age =
            r.ageCtrl.text.trim().isEmpty ? null : int.parse(r.ageCtrl.text.trim());
        notifier.update(
          widget.existing!.id,
          r.nameCtrl.text,
          r.selectedTypes.toList(),
          age: age,
          canServeMultipleTimes: r.canServeMultipleTimes,
          minimumIntervalWeeks: r.minimumIntervalWeeks,
        );
      } else {
        for (final r in _rows) {
          final age = r.ageCtrl.text.trim().isEmpty
              ? null
              : int.parse(r.ageCtrl.text.trim());
          notifier.add(
            r.nameCtrl.text,
            r.selectedTypes.toList(),
            age: age,
            canServeMultipleTimes: r.canServeMultipleTimes,
            minimumIntervalWeeks: r.minimumIntervalWeeks,
          );
        }
      }
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage =
          e.toString().replaceFirst('Invalid argument(s): ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditMode ? 'Editar Voluntário' : 'Novo Voluntário'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._rows.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final row = entry.value;
                  return _VolunteerRowWidget(
                    row: row,
                    showRemove: _rows.length > 1,
                    rowNumber: _rows.length > 1 ? idx + 1 : null,
                    validator: _validator,
                    onRemove: () => _removeRow(idx),
                    onChanged: () => setState(() {}),
                  );
                }),
                if (!_isEditMode) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar outro voluntário'),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorMessage!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: _save,
          child: Text(_isEditMode ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }
}

// ─── Single row widget ────────────────────────────────────────────────────────

class _VolunteerRowWidget extends StatelessWidget {
  final _VolunteerRow row;
  final bool showRemove;
  final int? rowNumber;
  final VolunteerValidator validator;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _VolunteerRowWidget({
    required this.row,
    required this.showRemove,
    required this.rowNumber,
    required this.validator,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rowNumber != null) ...[
          Row(
            children: [
              Text('Voluntário $rowNumber',
                  style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              if (showRemove)
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Remover',
                  onPressed: onRemove,
                ),
            ],
          ),
        ],
        TextFormField(
          controller: row.nameCtrl,
          decoration: const InputDecoration(
              labelText: 'Nome', border: OutlineInputBorder()),
          validator: (v) => validator.validateName(v ?? ''),
          autofocus: rowNumber == null || rowNumber == 1,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: row.ageCtrl,
          decoration: const InputDecoration(
              labelText: 'Idade (opcional)',
              border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            final age = int.tryParse(v.trim());
            if (age == null || age < 1 || age > 120) {
              return 'Idade inválida';
            }
            return null;
          },
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 8),
        Text('Tipos de culto',
            style: Theme.of(context).textTheme.labelLarge),
        ...ServiceType.values.map((type) => CheckboxListTile(
              title: Text(type.label),
              value: row.selectedTypes.contains(type),
              onChanged: (v) {
                if (v == true) {
                  row.selectedTypes.add(type);
                } else {
                  row.selectedTypes.remove(type);
                }
                onChanged();
              },
              contentPadding: EdgeInsets.zero,
            )),
        CheckboxListTile(
          title:
              const Text('Pode servir mais de uma vez por mês'),
          value: row.canServeMultipleTimes,
          onChanged: (v) {
            row.canServeMultipleTimes = v ?? true;
            onChanged();
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (row.canServeMultipleTimes) ...[
          DropdownButtonFormField<int>(
            value: row.minimumIntervalWeeks,
            decoration: const InputDecoration(
                labelText: 'Intervalo mínimo',
                border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 semana')),
              DropdownMenuItem(value: 2, child: Text('2 semanas')),
              DropdownMenuItem(value: 3, child: Text('3 semanas')),
            ],
            onChanged: (v) {
              row.minimumIntervalWeeks = v ?? 1;
              onChanged();
            },
          ),
        ],
        if (rowNumber != null) const Divider(height: 24),
      ],
    );
  }
}
