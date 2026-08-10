import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../routing/router.dart';
import '../../state/app_state.dart';
import '../shared/api_errors.dart';
import '../shared/widgets.dart';

/// Collects name and city for customers who sign in directly via
/// "I need a service" (no pro booking context with pre-filled details).
class CustomerProfileSetupScreen extends ConsumerStatefulWidget {
  const CustomerProfileSetupScreen({super.key});

  @override
  ConsumerState<CustomerProfileSetupScreen> createState() =>
      _CustomerProfileSetupScreenState();
}

class _CustomerProfileSetupScreenState
    extends ConsumerState<CustomerProfileSetupScreen> {
  late TextEditingController _nameCtrl;
  int? _cityId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final customer = ref.read(customerProvider).profile;
    final proName = ref.read(profileProvider).fullName;
    _nameCtrl = TextEditingController(
      text: customer?.fullName?.trim().isNotEmpty == true
          ? customer!.fullName
          : (proName?.trim().isNotEmpty == true ? proName : ''),
    );
    _cityId = customer?.cityId ?? supportedCities.first.id;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final cityId = _cityId;
    if (name.isEmpty || cityId == null || _busy) return;

    setState(() => _busy = true);
    try {
      await ref.read(customerProvider.notifier).saveProfile(
            fullName: name,
            cityId: cityId,
          );
    } catch (e) {
      if (mounted) {
        showApiError(context, e, fallback: 'Could not save your details.');
      }
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    await ref.read(pushNotificationServiceProvider).syncTokenWithServer();
    if (!mounted) return;
    context.go(Routes.customerHome);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final phone = auth.phoneE164 ?? ref.watch(customerProvider).profile?.phoneE164 ?? '';

    return AppPage(
      title: 'Your details',
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const Text(
            'Tell us a bit about you so we can match you with nearby pros.',
            style: TextStyle(color: AppTheme.textMuted, height: 1.45),
          ),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Phone: $phone',
              style: const TextStyle(
                color: AppTheme.textFaint,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name',
              hintText: 'e.g. Priya Kumar',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _cityId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Your city'),
            items: [
              for (final city in supportedCities)
                DropdownMenuItem(
                  value: city.id,
                  child: Text('${city.name}, ${city.state}'),
                ),
            ],
            onChanged: (v) => setState(() => _cityId = v),
          ),
        ],
      ),
      bottom: FilledButton(
        onPressed: _nameCtrl.text.trim().isNotEmpty &&
                _cityId != null &&
                !_busy
            ? _save
            : null,
        child: _busy
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('Continue'),
      ),
    );
  }
}
