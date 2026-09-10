# Raw captures

These are straight device screenshots at native resolution, with no
framing or captions. `scripts/generate_store_assets.py` reads them and
produces the promo cards for both stores.

| File | Scene |
| --- | --- |
| `home.png` | Home dashboard — balance card and the feature menu |
| `finance.png` | Keuangan — balance, six-month chart, category donut |
| `budget.png` | Budget Kategori — limits with progress bars in three states |
| `calendar.png` | Kalender — a day with an event selected |
| `alarm.png` | Alarm — two active alarms and one disabled |
| `password.png` | Password Manager — saved entries, values hidden |
| `converter.png` | Konversi — currency tab with a live rate |

Captured on `emulator-5554` (1080x1920). Any portrait phone at a similar
or higher resolution works — the generator scales to fit and strips the
system navigation bar automatically.

## Retaking them

The captures need realistic content, so seed the app first. `lib/dev_seed.dart`
is **not** in the repo (it is a throwaway); recreate it as a function that
writes a handful of transactions, budgets, events, alarms and passwords
through the normal repositories, call it from `main()` behind
`const bool.fromEnvironment('SEED_DEMO')`, then:

```bash
flutter build apk --debug --dart-define=SEED_DEMO=true
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
```

Before capturing, put the status bar into demo mode so every shot shows
the same clean 9:41 / full battery / full signal:

```bash
adb shell settings put global sysui_demo_allowed 1
adb shell am broadcast -a com.android.systemui.demo -e command enter
adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0941
adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100 -e plugged false
adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4 -e fully true
adb shell am broadcast -a com.android.systemui.demo -e command network -e mobile hide
adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false
# when finished:
adb shell am broadcast -a com.android.systemui.demo -e command exit
```

Capture each screen with:

```bash
adb -s emulator-5554 exec-out screencap -p > store_assets/screenshots/raw/home.png
```

Then regenerate the promo cards:

```bash
python3 scripts/generate_store_assets.py
```
