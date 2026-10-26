import 'parse.dart';

class Address {
  final int id;
  final String label; // HOME / WORK / OTHER
  final String fullName;
  final String phone;
  final String line1;
  final String line2;
  final String landmark;
  final String city;
  final String pincode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.line1,
    required this.line2,
    required this.landmark,
    required this.city,
    required this.pincode,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: asInt(j['id']),
        label: asString(j['label'] ?? j['address_type'], 'HOME'),
        fullName: asString(j['full_name'] ?? j['name']),
        phone: asString(j['phone']),
        line1: asString(j['line1'] ?? j['address_line1'] ?? j['house_no']),
        line2: asString(j['line2'] ?? j['address_line2'] ?? j['area']),
        landmark: asString(j['landmark']),
        city: asString(j['city']),
        pincode: asString(j['pincode'] ?? j['postal_code']),
        latitude: j['latitude'] == null ? null : asDouble(j['latitude']),
        longitude: j['longitude'] == null ? null : asDouble(j['longitude']),
        isDefault: asBool(j['is_default']),
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'full_name': fullName,
        'phone': phone,
        'line1': line1,
        'line2': line2,
        'landmark': landmark,
        'city': city,
        'pincode': pincode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'is_default': isDefault,
      };

  /// One-line version for the checkout summary.
  String get oneLine => [line1, line2, landmark, city, pincode]
      .where((s) => s.trim().isNotEmpty)
      .join(', ');

  String get labelPretty {
    switch (label.toUpperCase()) {
      case 'HOME':
        return 'Home';
      case 'WORK':
        return 'Work';
      default:
        return 'Other';
    }
  }
}
