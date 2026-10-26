import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/address.dart';
import '../data/services/api_client.dart';
import 'auth_provider.dart';
import 'providers.dart';

final addressListProvider = FutureProvider<List<Address>>((ref) async {
  if (!ref.watch(authProvider).isSignedIn) return const [];
  return ref.watch(addressRepositoryProvider).fetchAll();
});

/// Which address the user picked at checkout. Null means "use the default".
final selectedAddressIdProvider = StateProvider<int?>((ref) => null);

/// The address we will actually deliver to: the chosen one, else the default,
/// else the first one in the list.
final activeAddressProvider = Provider<Address?>((ref) {
  final list = ref.watch(addressListProvider).valueOrNull ?? const <Address>[];
  if (list.isEmpty) return null;

  final chosenId = ref.watch(selectedAddressIdProvider);
  if (chosenId != null) {
    for (final a in list) {
      if (a.id == chosenId) return a;
    }
  }
  for (final a in list) {
    if (a.isDefault) return a;
  }
  return list.first;
});

class AddressActions {
  final Ref ref;
  const AddressActions(this.ref);

  Future<String?> save(Address a) async {
    try {
      final repo = ref.read(addressRepositoryProvider);
      final saved = a.id == 0 ? await repo.create(a) : await repo.update(a);
      ref.invalidate(addressListProvider);
      ref.read(selectedAddressIdProvider.notifier).state = saved.id;
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> delete(int id) async {
    try {
      await ref.read(addressRepositoryProvider).delete(id);
      if (ref.read(selectedAddressIdProvider) == id) {
        ref.read(selectedAddressIdProvider.notifier).state = null;
      }
      ref.invalidate(addressListProvider);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> setDefault(int id) async {
    try {
      await ref.read(addressRepositoryProvider).setDefault(id);
      ref.invalidate(addressListProvider);
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}

final addressActionsProvider =
    Provider<AddressActions>((ref) => AddressActions(ref));
