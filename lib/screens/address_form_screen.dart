import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/models/address.dart';
import '../providers/address_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  final Address? existing;
  const AddressFormScreen({super.key, this.existing});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _line1;
  late final TextEditingController _line2;
  late final TextEditingController _landmark;
  late final TextEditingController _city;
  late final TextEditingController _pincode;

  late String _label;
  late bool _isDefault;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    final user = ref.read(authProvider).user;

    _name = TextEditingController(text: a?.fullName ?? user?.fullName ?? '');
    _phone = TextEditingController(text: a?.phone ?? user?.phone ?? '');
    _line1 = TextEditingController(text: a?.line1 ?? '');
    _line2 = TextEditingController(text: a?.line2 ?? '');
    _landmark = TextEditingController(text: a?.landmark ?? '');
    _city = TextEditingController(text: a?.city ?? 'Guntur');
    _pincode = TextEditingController(text: a?.pincode ?? '');
    _label = a?.label.toUpperCase() ?? 'HOME';
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _line1,
      _line2,
      _landmark,
      _city,
      _pincode,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit address' : 'New address'),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.textSecondary,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // ------------------------------------------------- label chips
            Row(
              children: ['HOME', 'WORK', 'OTHER'].map((l) {
                final active = _label == l;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _label = l),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: active ? AppColors.red : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: active ? AppColors.red : AppColors.stroke,
                        ),
                      ),
                      child: Text(
                        l[0] + l.substring(1).toLowerCase(),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                          color: active
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            _field(_name, 'Full name', required: true),
            _field(
              _phone,
              'Phone number',
              required: true,
              keyboard: TextInputType.phone,
              maxLength: 10,
              digitsOnly: true,
              validator: (v) =>
                  (v ?? '').trim().length == 10 ? null : 'Enter 10 digits',
            ),
            _field(_line1, 'House / flat / building', required: true),
            _field(_line2, 'Street, area'),
            _field(_landmark, 'Landmark (optional)'),
            _field(_city, 'City', required: true),
            _field(
              _pincode,
              'Pincode',
              required: true,
              keyboard: TextInputType.number,
              maxLength: 6,
              digitsOnly: true,
              validator: (v) =>
                  (v ?? '').trim().length == 6 ? null : 'Enter 6 digits',
            ),

            const SizedBox(height: 6),
            SwitchListTile.adaptive(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              activeColor: AppColors.red,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Make this my default address',
                style: TextStyle(fontSize: 14.5),
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEdit ? 'Save changes' : 'Save address'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    int? maxLength,
    bool digitsOnly = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLength: maxLength,
        textCapitalization: digitsOnly
            ? TextCapitalization.none
            : TextCapitalization.words,
        inputFormatters:
            digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          counterText: '',
        ),
        validator: validator ??
            (required
                ? (v) => (v ?? '').trim().isEmpty ? 'Required' : null
                : null),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final address = Address(
      id: widget.existing?.id ?? 0,
      label: _label,
      fullName: _name.text.trim(),
      phone: _phone.text.trim(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim(),
      landmark: _landmark.text.trim(),
      city: _city.text.trim(),
      pincode: _pincode.text.trim(),
      latitude: widget.existing?.latitude,
      longitude: widget.existing?.longitude,
      isDefault: _isDefault,
    );

    final error = await ref.read(addressActionsProvider).save(address);

    if (!mounted) return;
    setState(() => _saving = false);

    if (error == null) {
      Navigator.pop(context);
      showToast(context, _isEdit ? 'Address updated' : 'Address saved');
    } else {
      showToast(context, error, error: true);
    }
  }

  Future<void> _delete() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete this address?'),
        content: const Text('You can always add it again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => _saving = true);
    final error =
        await ref.read(addressActionsProvider).delete(widget.existing!.id);

    if (!mounted) return;
    setState(() => _saving = false);

    if (error == null) {
      Navigator.pop(context);
      showToast(context, 'Address deleted');
    } else {
      showToast(context, error, error: true);
    }
  }
}
