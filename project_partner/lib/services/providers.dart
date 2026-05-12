import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'data_service.dart';
import 'mock_data_service.dart';

/// Single source of truth for the data backend.
///
/// Part A points this at [MockDataService]. When Person 2 introduces
/// FirebaseDataService, the ONLY change needed here is to swap the
/// implementation returned below. Every screen depends on this provider,
/// never on a concrete implementation, so nothing else has to change.
final dataServiceProvider = Provider<DataService>((ref) {
  return MockDataService();
});

/// Reactive auth state. Emits null when signed out.
final currentUserStreamProvider = StreamProvider<User?>((ref) {
  final svc = ref.watch(dataServiceProvider);
  return svc.currentUserChanges();
});
