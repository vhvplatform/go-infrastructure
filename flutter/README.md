# Flutter - Mobile Applications

This directory contains Flutter-based mobile applications for iOS and Android.

## Structure

```
flutter/
├── app-name-1/          # Mobile app 1
├── app-name-2/          # Mobile app 2
└── shared/              # Shared widgets and utilities
```

## Getting Started

Each Flutter application should be a separate Flutter project with:
- `pubspec.yaml` - Dependencies and configuration
- `lib/` - Source code
- `android/` - Android-specific code
- `ios/` - iOS-specific code
- `README.md` - App-specific documentation

## Development

```bash
cd flutter/app-name
flutter pub get
flutter run
```

## Build

```bash
# For Android
flutter build apk

# For iOS
flutter build ios
```

## Testing

```bash
flutter test
```
