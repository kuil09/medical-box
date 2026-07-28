import 'local_data_lifecycle.dart';

class AccountDeletionCoordinator {
  AccountDeletionCoordinator(this._localDataLifecycle);

  final LocalDataLifecycle _localDataLifecycle;

  Future<void> delete({
    required Future<void> Function() deleteAccount,
    required bool deleteDeviceData,
  }) async {
    await deleteAccount();
    if (deleteDeviceData) {
      await _localDataLifecycle.deleteAllLocalData();
    }
  }
}
