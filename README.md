# Igreja em Escala

A cross-platform Flutter app for managing and generating volunteer service schedules for churches.

## Features

- **Schedule generation** — Automatically generates monthly schedules for volunteers based on service type, frequency constraints, and age-group pairing rules
- **Volunteer management** — Full CRUD for volunteers with service type assignments, age, and availability settings
- **CSV import/export** — Bulk-manage volunteers via CSV files
- **PDF export** — Print-ready schedule export with church name and service type headers
- **In-place editing** — Reassign volunteers to specific dates after a schedule is generated
- **Dark mode** — Toggle between light and dark themes
- **Responsive layout** — Bottom navigation bar on mobile, navigation rail on tablets/desktop
- **Portuguese localization** — UI fully in pt-BR

## Screens

| Screen | Description |
|---|---|
| Home | Lists all generated schedules sorted by date |
| Volunteers | Add, edit, delete, import, and export volunteers |
| Generate Schedule | Select service type, month, and generation options |
| Schedule Detail | View assignments, reassign volunteers, export to PDF |
| Settings | Set church name and toggle dark mode |

## Schedule Generation Rules

- **Service types**: Weekend (Friday + Sunday), Sunday Only, Friday Only
- **Age-group pairing**: Optionally require one minor (<18) and one adult (≥18) per day
- **Volunteers per day**: Configure 1 or 2 volunteers per scheduled day
- **Minimum interval**: Volunteers can have a minimum gap (in weeks) between assignments
- **Single-use flag**: Mark volunteers as available only once per schedule

## Getting Started

### Prerequisites

- Flutter SDK `^3.11.1`
- Dart SDK `^3.11.1`

### Install and run

```bash
flutter pub get
flutter run
```

### Build

```bash
flutter build apk       # Android
flutter build ios       # iOS
flutter build web       # Web
```

### Tests

```bash
flutter test
flutter analyze
```

## Architecture

```
lib/
├── main.dart               # Entry point
├── app.dart                # App widget, router, providers
├── core/
│   ├── providers/          # ChangeNotifier state (volunteers, schedules, settings)
│   └── theme/              # Material 3 light/dark themes
└── features/
    ├── home/               # Schedule list screen
    ├── schedule/           # Generation, view, PDF export, editor logic
    ├── service_type/       # ServiceType enum (Weekend, Sunday, Friday)
    ├── volunteers/         # Volunteer CRUD, CSV import/export
    └── settings/           # Church name, dark mode
```

- **State management**: Provider (`ChangeNotifier`)
- **Navigation**: GoRouter with a bottom navigation shell
- **PDF generation**: `pdf` + `printing` packages with NotoSans Unicode font
- **File I/O**: `file_picker` + `path_provider`

## CSV Format

Volunteer CSV columns:

```
Nome,Idade,Tipos de Culto,Pode Servir Multiplas Vezes,Intervalo Minimo Semanas
```

Service types are pipe-delimited enum names: `weekendService`, `sundayOnly`, `fridayOnly`.

## License

See [LICENSE](LICENSE).

