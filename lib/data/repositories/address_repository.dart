import '../../core/constants.dart';
import '../models/address.dart';
import '../models/parse.dart';
import '../services/api_client.dart';

class AddressRepository {
  final ApiClient api;
  const AddressRepository(this.api);

  Future<List<Address>> fetchAll() async {
    final data = await api.get(Api.addresses);
    return unwrapList(data).map(Address.fromJson).toList();
  }

  Future<Address> create(Address a) async {
    final data = await api.post(Api.addresses, body: a.toJson());
    return Address.fromJson(Map<String, dynamic>.from(data));
  }

  Future<Address> update(Address a) async {
    final data = await api.patch(Api.addressDetail(a.id), body: a.toJson());
    return Address.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> delete(int id) async {
    await api.delete(Api.addressDetail(id));
  }

  Future<Address> setDefault(int id) async {
    final data = await api.patch(
      Api.addressDetail(id),
      body: {'is_default': true},
    );
    return Address.fromJson(Map<String, dynamic>.from(data));
  }
}
