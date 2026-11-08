# Minggu 11 — Refactor Layer-First Campus Notify

Folder ini berisi hasil kloning project `09-week-9/campus_notify` ke
`11-week-11/campus_notify`, lalu direfaktor dari struktur berbasis fitur
(`data/`, `messaging/`, `providers/`, `pages/`) menjadi struktur **layer-first**:

```text
lib/
├── domain/       # entity, kontrak repository, usecase, util murni
├── data/         # datasource, implementasi repository, network, storage, service
└── presentation/ # provider Riverpod, router, pages, widgets
```

Arah dependensi dijaga satu arah: `presentation -> domain <- data`. Layer
`domain` tidak mengimpor Flutter, Firebase, Dio, maupun implementasi data.

## Menjalankan

```bash
cd campus_notify
flutter pub get
flutter analyze
flutter test
flutter run
```

Detail fitur, struktur lengkap, dan dokumentasi pengujian ada di
[`campus_notify/README.md`](campus_notify/README.md).
