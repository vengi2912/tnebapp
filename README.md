# TNEB Bill Splitter

A Flutter (Android) app to split shared TNEB electricity bills across a
6-house residential building fed by 3 main meters, 4 sub meters and 1
common water pump meter, using the official Tamil Nadu domestic slab
tariff.

> **Important:** this project was generated in a sandbox with no Flutter
> SDK, Android SDK, or internet access, so it could **not** be compiled or
> run here. The Dart code and Android project files are hand-written to be
> correct and complete, but you must build it once on your own machine to
> confirm everything compiles cleanly and to produce the APK.

## 1. Prerequisites

- Flutter SDK (3.22+) installed - https://docs.flutter.dev/get-started/install
- Android SDK / Android Studio (or just `sdkmanager` + command-line tools)
- A physical device or emulator running Android 5.0 (API 21) or higher

## 2. First-time setup

```bash
cd tneb_bill_splitter
flutter pub get
```

### Gradle wrapper note
This project ships hand-written `android/gradlew`, `android/gradlew.bat`
and `gradle-wrapper.properties`, but **not** the binary
`gradle-wrapper.jar` (it can't be produced without network access). Do
ONE of the following before your first build:

- **Easiest:** open the project in Android Studio once - it will
  regenerate the missing wrapper jar automatically on Gradle sync, or
- Run `gradle wrapper --gradle-version 8.7` inside `android/` if you have
  Gradle installed globally, or
- Run `flutter create --platforms=android .` from the project root - this
  regenerates a fresh, guaranteed-correct `android/` folder matching your
  installed Flutter version (it will not overwrite your `lib/` code), then
  just confirm `applicationId`, the app icons, and `AndroidManifest.xml`
  still match what's described below.

## 3. Run in debug mode

```bash
flutter run
```

## 4. Build the release APK

```bash
flutter build apk --release
```

The signed APK will be at:
`build/app/outputs/flutter-apk/app-release.apk`

It's currently signed with the auto-generated Android debug key so the
build works out of the box. **Before publishing anywhere**, replace this
with your own upload keystore:

1. `keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Create `android/key.properties` with your keystore details.
3. Update `android/app/build.gradle`'s `signingConfigs.release` block to
   read from `key.properties` instead of `signingConfigs.debug`.

## 5. Project structure

```
lib/
  models/        House, Main Meter, Tariff Slab, and Bill Record data classes
  services/      Tariff slab calculator, bill-splitting engine, SQLite,
                 SharedPreferences settings, PDF generation & sharing
  providers/     AppState (ChangeNotifier) - single source of truth
  screens/       Home, Result, History, Settings
  widgets/       Reusable Section Card, Number Input, House Result Tile
  theme/         Material 3 light/dark theme
```

## 6. How the calculation works

**Tariff (slab-wise, telescopic):** each main meter's *physical* total
units (sum of its houses' base + sub-meter readings) is run through the
official TN domestic tariff table:

- Total ≤ 500: 1-200 free, 201-400 @ ₹4.70, 401-500 @ ₹6.30
- Total > 500: 1-100 free, 101-400 @ ₹4.70, 401-500 @ ₹6.30,
  501-600 @ ₹8.40, 601-800 @ ₹9.45, 801-1000 @ ₹10.50, above 1000 @ ₹11.55

Only the units that actually fall inside each slab are billed at that
slab's rate (not the whole consumption) - see
`lib/services/tariff_service.dart`.

**Splitting logic:** the common water pump's units are divided equally
among every house that shares it, giving each house a "pump share". Each
house's **Final Units** = its own units (+ any dedicated sub meter) + its
pump share. A meter's fixed total bill is then split between its houses
in proportion to their Final Units:

```
House Bill = (House Final Units / Sum of Final Units on that meter) × Meter's Total Bill
```

Because these ratios always sum to 1 within a meter group, the sum of all
house bills exactly equals the sum of the 3 meters' bills - no rounding
leakage.

**House ↔ meter ↔ sub-meter ↔ pump wiring is configurable** from
Settings, since real buildings wire this differently. The default layout
assumes 2 houses per main meter, the first 4 houses each have one
dedicated sub meter, and all 6 houses share the water pump equally -
adjust this in **Settings → House Wiring & Pump Sharing** to match your
actual building.

## 7. Features implemented

- Live Main Meter 1/2/3 total-units dashboard
- All required input fields (6 houses, 4 sub meters, water pump + shared-by)
- Exact slab-wise TNEB tariff billing (editable rates in Settings)
- Proportional bill distribution per meter
- Full result screen (per-house + per-meter + grand totals)
- Save monthly records to SQLite, browse/delete previous bills
- Export bill as PDF and share it (WhatsApp, email, etc. via system share sheet)
- Editable tariff values, Light/Dark mode, Material 3 UI
- Input validation (numeric, non-negative, decimal support), ₹ currency formatting
