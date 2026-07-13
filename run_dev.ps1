Copy-Item devjeson/google-services.json android/app/google-services.json -Force
flutter run --dart-define=DEV=true
