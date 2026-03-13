import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/schedule_notifier.dart';
import '../../../features/schedule/domain/models/schedule.dart';
import '../../../features/service_type/domain/extensions/service_type_extension.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final schedules = context.watch<ScheduleNotifier>().schedules;
    return Scaffold(
      appBar: AppBar(title: const Text('Escalas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/schedule/generate'),
        icon: const Icon(Icons.add),
        label: const Text('Nova Escala'),
      ),
      body: schedules.isEmpty
          ? _EmptyState(onGenerate: () => context.go('/schedule/generate'))
          : _ScheduleList(schedules: schedules),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onGenerate;
  const _EmptyState({required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 64, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 16),
          Text('Nenhuma escala gerada',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Toque em "Nova Escala" para começar.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onGenerate,
            icon: const Icon(Icons.add),
            label: const Text('Gerar Escala'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  final List<Schedule> schedules;
  const _ScheduleList({required this.schedules});

  @override
  Widget build(BuildContext context) {
    final sorted = [...schedules]..sort((a, b) {
        final y = b.year.compareTo(a.year);
        return y != 0 ? y : b.month.compareTo(a.month);
      });
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final s = sorted[index];
        final monthYear =
            DateFormat('MMMM yyyy', 'pt_BR').format(DateTime(s.year, s.month));
        final label =
            '${monthYear[0].toUpperCase()}${monthYear.substring(1)}';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text('${s.serviceType.label} — $label'),
            subtitle: Text('${s.entries.length} dias'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/schedule/${s.id}'),
          ),
        );
      },
    );
  }
}
