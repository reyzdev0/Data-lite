# Modern Notes App (Flutter)

Paket siap pakai untuk GitHub Actions!

## Isi File:
- `lib/main.dart` — Kode lengkap aplikasi Notes Material 3.
- `pubspec.yaml` — Konfigurasi package (`shared_preferences`).
- `.github/workflows/build-apk.yml` — Workflow GitHub Actions otomatis build APK (sekalian menjalankan `flutter create --platforms=android .` jika folder `android/` belum ada di repo).

## Cara Pakai di GitHub:
1. Ekstrak file ZIP ini.
2. Push isinya ke repository GitHub baru kamu.
3. Buka tab **Actions** di GitHub, workflow **Build Flutter APK** akan berjalan otomatis dan menghasilkan file `.apk` siap unduh di bagian **Artifacts**.
