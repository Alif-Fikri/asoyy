# Privacy Policy — Beres

**Last updated: 10 September 2026**

Beres ("the app") is an offline personal toolkit: calendar, finance
tracking, alarms, calculator, unit and currency conversion, and a password
manager. This policy explains exactly what the app does and does not do
with your information.

## The short version

Beres has no account, no login, and no server of its own. It never asks
for your name, email, phone number, contacts, photos, camera, microphone,
or location. Nothing you enter into the app is uploaded anywhere. The only
network request the app ever makes is to fetch public currency exchange
rates, and that request carries no information about you.

## What is stored on your device

Everything you create in the app is written to the app's own private
storage on your device:

- Financial transactions — title, amount, type, category, date, notes
- Monthly budget limits per category
- Recurring transactions and their reminder schedule
- Calendar events and your payday date
- Alarms, including any ringtone you picked
- Password manager entries — title, username, password, website, notes
- Your display name, theme choice, and language choice
- Your PIN or unlock pattern, if you set one

This never leaves the device. There is no cloud sync and no backup server.
Uninstalling the app deletes all of it.

## The password manager

Password entries are stored in the app's private storage, the same
sandboxed area used for the rest of your data, which other apps on the
device cannot read. Access is gated behind the unlock method you choose:
your device's fingerprint or face biometric, a pattern, or a six-digit
PIN.

Two things are worth being clear about:

- Entries are **not** end-to-end encrypted with a key derived from your
  PIN. They are protected by Android's app sandbox and by the unlock
  screen, not by a separate encryption layer. On a rooted or compromised
  device, that protection is weaker.
- If you use the **Export CSV** feature, the file written to your device
  contains your passwords **in plain text**, so that other password
  managers can read it. Anything you then do with that file — sharing it,
  syncing it, leaving it in Downloads — is outside the app's control.
  Delete it once you are done with it.

## Network use

The app makes exactly one kind of network request: a `GET` to
`https://open.er-api.com/v6/latest/USD`, used by the currency converter to
fetch public exchange rates. The request sends no parameters, no API key,
and no identifier of any kind — the response is the same for everyone.
The fetched rates are cached on your device so the converter keeps working
offline.

If you never open the currency converter tab, the app can be used entirely
without a network connection.

## Notifications and alarms

The app asks for notification permission so it can ring your alarms and
remind you about recurring bills the day before they are due. It also uses
Android's exact alarm and full-screen notification permissions so an alarm
rings on time and shows a full-screen screen when it does. These are used
only for alarms and reminders you created yourself.

## Advertising and analytics

There are none. Beres contains no advertising SDK, no analytics SDK, no
crash reporting service, and no third-party tracker of any kind.

## Children

The app is not directed at children and collects no personal data from
anyone, including children.

## Your control over your data

- **Delete individual items** — every transaction, event, alarm, and
  password entry can be deleted inside the app.
- **Export** — finance data and password entries can be exported to CSV,
  saved to your device and shared wherever you choose.
- **Delete everything** — uninstalling the app removes all data. The
  password manager also has a reset option that wipes stored entries and
  your unlock method.

## Changes to this policy

If the app ever starts collecting data, uses a different network service,
or adds advertising, this policy will be updated and the "last updated"
date above will change before that version is released.

## Contact

Questions about this policy can be sent to the developer through the
contact address listed on the app's store page.
