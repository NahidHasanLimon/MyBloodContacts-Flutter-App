import 'package:blood_contacts/src/features/contacts/data/contacts_store.dart';
import 'package:blood_contacts/src/features/contacts/data/google_drive_sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const String dailyAutoSyncTask = 'blood_contacts_daily_auto_sync';
const _maxAutoSyncAttemptsPerDay = 3;
const _autoSyncRetryInterval = Duration(minutes: 30);

@pragma('vm:entry-point')
void backgroundSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != dailyAutoSyncTask) return true;

    final prefs = await SharedPreferences.getInstance();
    final store = ContactsStore(prefs);
    await store.init();

    final autoSyncEnabled = store.loadAutoSyncEnabled();
    if (!autoSyncEnabled) return true;

    final now = DateTime.now();
    if (!store.canAttemptAutoSyncNow(
      now,
      maxAttemptsPerDay: _maxAutoSyncAttemptsPerDay,
      retryInterval: _autoSyncRetryInterval,
    )) {
      return true;
    }
    await store.recordAutoSyncAttempt(now);
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      const reason = 'No internet connection.';
      await store.addSyncHistory(
        now,
        status: 'failed',
        message: reason,
      );
      await store.saveLastSyncStatus('failed');
      await _notifyAutoSyncFailure(store, reason, now);
      return true;
    }

    final driveFolder = store.loadDriveFolder()?.trim();
    if (driveFolder == null || driveFolder.isEmpty) {
      const reason = 'Google Drive not connected.';
      await store.addSyncHistory(
        now,
        status: 'cancelled',
        message: reason,
      );
      await store.saveLastSyncStatus('cancelled');
      await _notifyAutoSyncFailure(store, reason, now, cancelled: true);
      return true;
    }

    try {
      await GoogleDriveSyncService.initializeGoogleSignIn();
      final service = GoogleDriveSyncService();
      final result = await service.sync(
        store: store,
        allowInteractiveAuth: false,
      );

      await store.addSyncHistory(
        now,
        status: 'success',
        contactCount: result.contactCount,
        needCount: result.needCount,
      );
      await store.saveLastSyncStatus('success');
      await store.resetAutoSyncAttemptTracking(now);

      final notifySyncEvents = store.loadNotifySyncEventsEnabled();
      if (notifySyncEvents) {
        await store.upsertNotification(
          code: 'sync_success_${now.microsecondsSinceEpoch}',
          title: 'Auto-sync successful',
          message:
              'Synced ${result.contactCount} contacts and ${result.needCount} needs.',
          createdAt: now,
        );
      }
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      final lower = message.toLowerCase();
      final terminated =
          lower.contains('terminate') ||
          lower.contains('terminated') ||
          lower.contains('timeout') ||
          lower.contains('timed out');
      final status = terminated ? 'terminated' : 'failed';
      final reason = _syncUserMessage(message);
      await store.addSyncHistory(
        now,
        status: status,
        message: reason,
      );
      await store.saveLastSyncStatus(status);
      final notifySyncEvents = store.loadNotifySyncEventsEnabled();
      final notifySyncFailed = store.loadNotifySyncFailedEnabled();

      if (notifySyncEvents) {
        await store.upsertNotification(
          code: 'sync_${status}_${now.microsecondsSinceEpoch}',
          title: terminated ? 'Auto-sync terminated' : 'Auto-sync failed',
          message: reason,
          createdAt: now,
        );
      }

      if (notifySyncFailed && !notifySyncEvents) {
        await store.upsertNotification(
          code: 'sync_failed',
          title: 'Your last sync failed',
          message:
              'Please sync your contacts again to keep your blood network safe.',
          createdAt: now,
        );
      }
      await _notifyAutoSyncFailure(
        store,
        reason,
        now,
        terminated: terminated,
      );
    }

    return true;
  });
}

Future<void> _notifyAutoSyncFailure(
  ContactsStore store,
  String reason,
  DateTime now, {
  bool cancelled = false,
  bool terminated = false,
}) async {
  await store.upsertNotification(
    code: 'auto_sync_failed_${now.microsecondsSinceEpoch}',
    title: cancelled
        ? 'Auto-sync cancelled'
        : terminated
        ? 'Auto-sync terminated'
        : 'Auto-sync failed',
    message: reason,
    createdAt: now,
  );
}

String _syncUserMessage(String rawMessage) {
  final lower = rawMessage.toLowerCase();
  if (lower.contains('internet') ||
      lower.contains('network') ||
      lower.contains('socket') ||
      lower.contains('host lookup')) {
    return 'No internet connection. Please try again online.';
  }
  if (lower.contains('auth') ||
      lower.contains('sign in') ||
      lower.contains('unauthorized') ||
      lower.contains('permission')) {
    return 'Google Drive authorization failed. Please reconnect and try again.';
  }
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'Sync timed out. Please try again.';
  }
  if (lower.contains('cancel') ||
      lower.contains('canceled') ||
      lower.contains('aborted')) {
    return 'Sync was cancelled.';
  }
  return 'Sync could not complete. Please try again.';
}
