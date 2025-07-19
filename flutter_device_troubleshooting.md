# Řešení problémů s připojením zařízení ve Flutteru

## Kroky k řešení chyby "No connected devices found"

### 1. Zkontrolujte připojená zařízení
- Spusťte příkaz `flutter devices` pro zobrazení všech dostupných zařízení
- Ujistěte se, že máte připojené fyzické zařízení přes USB nebo je spuštěný emulátor/simulátor

### 2. Pro Android zařízení
- Ujistěte se, že máte povolené USB ladění v nastavení vývojáře
- Zkontrolujte, že jste potvrdili oprávnění pro USB ladění na zařízení
- Zkuste příkaz `adb devices` pro ověření, zda ADB vidí vaše zařízení

### 3. Pro iOS zařízení
- Ujistěte se, že máte nainstalovaný Xcode a iOS simulátor
- Pro fyzické zařízení musíte mít nakonfigurovaný vývojářský účet v Xcode

### 4. Spuštění emulátorů/simulátorů
- Android: `flutter emulators --launch <id_emulátoru>` nebo spusťte emulátor přes Android Studio
- iOS: `open -a Simulator` nebo spusťte simulátor přes Xcode

### 5. Restart Flutter
- Zkuste restartovat Flutter služby pomocí příkazu `flutter doctor`

### 6. Instalace Flutter SDK
- Pokud jste Flutter ještě nenainstalovali, navštivte [flutter.dev/setup](https://flutter.dev/setup) pro kompletní návod k instalaci

### 7. Řešení konkrétních problémů
- Pokud používáte Android Studio nebo VS Code, zkuste restartovat IDE
- Zkontrolujte, zda je váš Flutter SDK aktuální pomocí `flutter upgrade`

Pokud problém přetrvává, spusťte `flutter doctor -v` a zkontrolujte, zda tam nejsou další informace o problému.
