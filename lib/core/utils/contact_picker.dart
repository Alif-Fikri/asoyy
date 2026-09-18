import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_toast.dart';

Future<String?> pickContactName(BuildContext context) async {
  final status = await FlutterContacts.permissions.request(PermissionType.read);
  final granted = status == PermissionStatus.granted || status == PermissionStatus.limited;
  if (!granted) {
    if (context.mounted) {
      AppToast.show(context, context.strings.contact_permission_denied);
    }
    return null;
  }

  final contact = await FlutterContacts.native.showPicker();
  return contact?.displayName?.trim();
}
