import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/common.dart';

/// Add a delivery address, with an optional GPS pin and a serviceability check.
class AddressForm extends StatefulWidget {
  const AddressForm({super.key});

  static Future<bool> open(BuildContext context) async =>
      await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const AddressForm(),
      ) ??
      false;

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _l1 = TextEditingController();
  final _l2 = TextEditingController();
  final _landmark = TextEditingController();
  final _city = TextEditingController(text: 'Narasaraopet');
  final _pin = TextEditingController();

  String _label = 'HOME';
  double? _lat, _lng;
  String _locMessage = '';
  bool _locating = false, _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    _name.text = u?.fullName ?? '';
    _phone.text = u?.phone ?? '';
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _l1, _l2, _landmark, _city, _pin]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _useLocation() async {
    setState(() {
      _locating = true;
      _locMessage = 'Finding you…';
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locMessage = 'Location permission denied. Type the address instead.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _lat = pos.latitude;
      _lng = pos.longitude;

      try {
        final places = await placemarkFromCoordinates(_lat!, _lng!);
        if (places.isNotEmpty) {
          final p = places.first;
          if (_l2.text.isEmpty) _l2.text = [p.subLocality, p.locality].where((e) => (e ?? '').isNotEmpty).join(', ');
          if (_pin.text.isEmpty) _pin.text = p.postalCode ?? '';
          if (p.locality != null && p.locality!.isNotEmpty) _city.text = p.locality!;
        }
      } catch (_) {/* reverse geocoding is a nicety, not a requirement */}

      final r = await context.read<OrderProvider>().checkServiceable(_lat!, _lng!);
      setState(() => _locMessage = '${r['message']} (${r['distance_km']} km away)');
    } catch (_) {
      setState(() => _locMessage = 'Could not get your location. Type the address instead.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<OrderProvider>().saveAddress({
        'label': _label,
        'receiver_name': _name.text.trim(),
        'receiver_phone': _phone.text.replaceAll(RegExp(r'\D'), ''),
        'line1': _l1.text.trim(),
        'line2': _l2.text.trim(),
        'landmark': _landmark.text.trim(),
        'city': _city.text.trim(),
        'pincode': _pin.text.trim(),
        if (_lat != null) 'latitude': _lat!.toStringAsFixed(6),
        if (_lng != null) 'longitude': _lng!.toStringAsFixed(6),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: .88,
          expand: false,
          builder: (_, controller) => Form(
            key: _form,
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              children: [
                Center(
                  child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                          color: PfcColors.ink600, borderRadius: BorderRadius.circular(9))),
                ),
                const SizedBox(height: 18),
                Text('Delivery address', style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 6),
                const Text('Drop a pin so the rider finds you the first time.',
                    style: TextStyle(color: PfcColors.textDim, fontSize: 13)),
                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: _locating ? null : _useLocation,
                  icon: _locating
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location_rounded, size: 19),
                  label: const Text('Use my current location'),
                ),
                if (_locMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_locMessage,
                        style: const TextStyle(fontSize: 12.5, color: PfcColors.gold200)),
                  ),
                const SizedBox(height: 18),

                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Phone', counterText: ''),
                      validator: (v) =>
                          RegExp(r'^[6-9]\d{9}$').hasMatch(v ?? '') ? null : 'Invalid',
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _l1,
                  decoration: const InputDecoration(labelText: 'House / flat / building'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _l2, decoration: const InputDecoration(labelText: 'Street / area')),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                        controller: _landmark,
                        decoration: const InputDecoration(labelText: 'Landmark')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pin,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Pincode', counterText: ''),
                      validator: (v) => (v ?? '').length == 6 ? null : 'Invalid',
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
                const SizedBox(height: 16),

                Row(
                  children: ['HOME', 'WORK', 'OTHER'].map((l) {
                    final on = _label == l;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _label = l),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: on ? PfcColors.goldGradient : null,
                            color: on ? null : PfcColors.ink700,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: on ? Colors.transparent : PfcColors.line),
                          ),
                          child: Text(l[0] + l.substring(1).toLowerCase(),
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: on ? PfcColors.onGold : PfcColors.textDim)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2))
                      : const Text('Save address'),
                ),
              ],
            ),
          ),
        ),
      );
}
