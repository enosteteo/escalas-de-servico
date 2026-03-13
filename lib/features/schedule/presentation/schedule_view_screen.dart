// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/schedule_notifier.dart';
import '../../../core/providers/settings_notifier.dart';
import '../../../core/providers/volunteer_notifier.dart';
import '../../../features/schedule/domain/models/schedule.dart';
import '../../../features/schedule/domain/models/schedule_entry.dart';
import '../../../features/schedule/domain/services/schedule_display_formatter.dart';
import '../../../features/schedule/domain/services/schedule_exporter.dart';
import '../../../features/service_type/domain/extensions/service_type_extension.dart';
import '../../../features/volunteers/domain/models/volunteer.dart';

class ScheduleViewScreen extends StatelessWidget {
  final String scheduleId;
  const ScheduleViewScreen({super.key, required this.scheduleId});

  @override
  Widget build(BuildContext context) {
    final schedule = context.watch<ScheduleNotifier>().findById(scheduleId);
    if (schedule == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Escala'),
          leading: BackButton(onPressed: () => context.go('/')),
        ),
        body: const Center(child: Text('Escala não encontrada.')),
      );
    }
    final volunteers = context.watch<VolunteerNotifier>().volunteers;
    final volunteerMap = {for (final v in volunteers) v.id: v};
    final churchName = context.watch<SettingsNotifier>().settings.churchName;
    final formatter = ScheduleDisplayFormatter();

    // Group entries by date so same-day volunteers appear on one line.
    final grouped = _groupByDate(schedule.entries);
    final dates = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(schedule.serviceType.label),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () =>
                _exportPdf(context, schedule, volunteerMap, churchName),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final entries = grouped[date]!;
          final names = entries
              .map((e) => volunteerMap[e.volunteerId]?.name ?? 'Desconhecido')
              .toList();
          final dateStr =
              DateFormat('dd/MM/yyyy (EEE)', 'pt_BR').format(date);
          final namesStr = formatter.joinNames(names);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.event),
              title: Text(dateStr),
              subtitle: Text(namesStr),
              trailing: const Icon(Icons.edit_outlined, size: 18),
              onTap: () => entries.length == 1
                  ? _showReassignDialog(
                      context,
                      schedule,
                      entries.first.date,
                      volunteers,
                      entries.first.volunteerId,
                    )
                  : _showGroupedReassignDialog(
                      context,
                      schedule,
                      entries,
                      volunteers,
                      volunteerMap,
                    ),
            ),
          );
        },
      ),
    );
  }

  Map<DateTime, List<ScheduleEntry>> _groupByDate(
      List<ScheduleEntry> entries) {
    final map = <DateTime, List<ScheduleEntry>>{};
    for (final e in entries) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  /// Dialog for days with multiple entries — lets user pick which volunteer to reassign.
  Future<void> _showGroupedReassignDialog(
    BuildContext context,
    Schedule schedule,
    List<ScheduleEntry> entries,
    List<Volunteer> volunteers,
    Map<String, Volunteer> volunteerMap,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reatribuir dia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Escolha qual voluntário reatribuir:'),
            const SizedBox(height: 8),
            ...entries.map((e) {
              final name =
                  volunteerMap[e.volunteerId]?.name ?? 'Desconhecido';
              return ListTile(
                title: Text(name),
                trailing: const Icon(Icons.edit_outlined, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReassignDialog(
                    context,
                    schedule,
                    e.date,
                    volunteers,
                    e.volunteerId,
                  );
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
        ],
      ),
    );
  }

  Future<void> _showReassignDialog(
    BuildContext context,
    Schedule schedule,
    DateTime entryDate,
    List<Volunteer> volunteers,
    String currentId,
  ) async {
    final eligible = volunteers
        .where((v) => v.serviceTypes.contains(schedule.serviceType))
        .toList();
    String? selected = currentId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Reatribuir dia'),
          content: DropdownButtonFormField<String>(
            value: selected,
            decoration: const InputDecoration(
                labelText: 'Voluntário', border: OutlineInputBorder()),
            items: eligible
                .map((v) =>
                    DropdownMenuItem(value: v.id, child: Text(v.name)))
                .toList(),
            onChanged: (v) => setState(() => selected = v),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Salvar')),
          ],
        ),
      ),
    );

    if (confirmed == true &&
        selected != null &&
        selected != currentId &&
        context.mounted) {
      try {
        context.read<ScheduleNotifier>().reassign(
              scheduleId: schedule.id,
              entryDate: entryDate,
              newVolunteerId: selected!,
              availableVolunteers: volunteers,
            );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  Future<void> _exportPdf(
    BuildContext context,
    Schedule schedule,
    Map<String, Volunteer> volunteerMap,
    String churchName,
  ) async {
    final exporter = ScheduleExporter();
    try {
      exporter.validateExport(churchName: churchName, schedule: schedule);
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Não é possível exportar'),
            content: Text(
                e.toString().replaceFirst('Invalid argument(s): ', '')),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK')),
            ],
          ),
        );
      }
      return;
    }

    final data = exporter.buildExportData(
      churchName: churchName,
      schedule: schedule,
      volunteerMap: {
        for (final e in volunteerMap.entries) e.key: e.value.name
      },
    );

    const weekdays = [
      '',
      'Segunda',
      'Terca',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sabado',
      'Domingo'
    ];
    final monthName = DateFormat('MMMM yyyy', 'pt_BR')
        .format(DateTime(data.year, data.month));
    final monthLabel =
        '${monthName[0].toUpperCase()}${monthName.substring(1)}';

    // Load Unicode-capable TTF fonts for proper character support
    pw.Font? regularFont;
    pw.Font? boldFont;
    try {
      final regularData =
          await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
      final boldData =
          await rootBundle.load('assets/fonts/NotoSans-Bold.ttf');
      regularFont = pw.Font.ttf(regularData);
      boldFont = pw.Font.ttf(boldData);
    } catch (_) {
      // Fallback: use built-in Helvetica (limited Unicode support)
      regularFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    final serviceLabel = '${data.serviceTypeLabel} - $monthLabel';

    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(data.churchName,
              style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(serviceLabel,
              style: pw.TextStyle(font: regularFont, fontSize: 14)),
          pw.SizedBox(height: 16),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Data',
                        style: pw.TextStyle(
                            font: boldFont,
                            fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text('Voluntario',
                        style: pw.TextStyle(
                            font: boldFont,
                            fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ...data.rows.map((row) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          '${DateFormat('dd/MM/yyyy', 'pt_BR').format(row.date)} (${weekdays[row.date.weekday]})',
                          style: pw.TextStyle(font: regularFont),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(row.volunteerName,
                            style: pw.TextStyle(font: regularFont)),
                      ),
                    ],
                  )),
            ],
          ),
        ],
      ),
    ));

    if (context.mounted) {
      await Printing.layoutPdf(onLayout: (_) async => doc.save());
    }
  }
}
