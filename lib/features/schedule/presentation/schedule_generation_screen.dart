// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/schedule_notifier.dart';
import '../../../core/providers/volunteer_notifier.dart';
import '../../../features/schedule/domain/models/generation_options.dart';
import '../../../features/service_type/domain/enums/service_type.dart';
import '../../../features/service_type/domain/extensions/service_type_extension.dart';

class ScheduleGenerationScreen extends StatefulWidget {
  const ScheduleGenerationScreen({super.key});

  @override
  State<ScheduleGenerationScreen> createState() =>
      _ScheduleGenerationScreenState();
}

class _ScheduleGenerationScreenState extends State<ScheduleGenerationScreen> {
  ServiceType _selectedType = ServiceType.weekendService;
  late int _selectedMonth;
  late int _selectedYear;
  String? _errorMessage;

  bool _requireAgeGroupPairing = false;
  int _volunteersPerDay = 1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  Future<void> _generate() async {
    setState(() => _errorMessage = null);
    final volunteers = context
        .read<VolunteerNotifier>()
        .volunteers
        .where((v) => v.serviceTypes.contains(_selectedType))
        .toList();

    if (volunteers.isEmpty) {
      setState(() => _errorMessage =
          'Nenhum voluntário está associado ao tipo "${_selectedType.label}".');
      return;
    }

    final scheduleNotifier = context.read<ScheduleNotifier>();
    if (scheduleNotifier.hasExisting(
        _selectedMonth, _selectedYear, _selectedType)) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Substituir escala'),
          content: const Text(
              'Já existe uma escala para este mês e tipo. Deseja substituí-la?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Substituir')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final options = GenerationOptions(
      requireAgeGroupPairing: _requireAgeGroupPairing,
      volunteersPerDay: _requireAgeGroupPairing ? 2 : _volunteersPerDay,
    );

    try {
      final schedule = scheduleNotifier.generate(
        month: _selectedMonth,
        year: _selectedYear,
        serviceType: _selectedType,
        volunteers: volunteers,
        options: options,
      );
      if (mounted) context.go('/schedule/${schedule.id}');
    } catch (e) {
      setState(() => _errorMessage =
          e.toString().replaceFirst('Invalid argument(s): ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerar Escala')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo de Culto',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...ServiceType.values.map((type) => RadioListTile<ServiceType>(
                  title: Text(type.label),
                  value: type,
                  groupValue: _selectedType,
                  onChanged: (v) => setState(() => _selectedType = v!),
                  contentPadding: EdgeInsets.zero,
                )),
            const SizedBox(height: 24),
            Text('Mês e Ano', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedMonth,
                    decoration: const InputDecoration(
                        labelText: 'Mês', border: OutlineInputBorder()),
                    items: List.generate(12, (i) {
                      final m = i + 1;
                      final name = DateFormat('MMMM', 'pt_BR')
                          .format(DateTime(2000, m));
                      return DropdownMenuItem(
                        value: m,
                        child: Text(
                            '${name[0].toUpperCase()}${name.substring(1)}'),
                      );
                    }),
                    onChanged: (v) => setState(() => _selectedMonth = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedYear,
                    decoration: const InputDecoration(
                        labelText: 'Ano', border: OutlineInputBorder()),
                    items: List.generate(5, (i) {
                      final y = DateTime.now().year + i - 1;
                      return DropdownMenuItem(
                          value: y, child: Text(y.toString()));
                    }),
                    onChanged: (v) => setState(() => _selectedYear = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Opções de Geração',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            CheckboxListTile(
              title:
                  const Text('Emparelhar menor de idade com adulto'),
              value: _requireAgeGroupPairing,
              onChanged: (v) =>
                  setState(() => _requireAgeGroupPairing = v ?? false),
              contentPadding: EdgeInsets.zero,
            ),
            if (!_requireAgeGroupPairing) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _volunteersPerDay,
                decoration: const InputDecoration(
                    labelText: 'Voluntários por dia',
                    border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 voluntário')),
                  DropdownMenuItem(value: 2, child: Text('2 voluntários')),
                ],
                onChanged: (v) =>
                    setState(() => _volunteersPerDay = v ?? 1),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color:
                            Theme.of(context).colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _generate,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Gerar Escala'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
