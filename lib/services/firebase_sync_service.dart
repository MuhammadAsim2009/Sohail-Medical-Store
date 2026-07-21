/// Sync service stub — logic will be rebuilt with new architecture.
/// The UI references SyncResult so we keep this minimal class here.
class SyncResult {
  final int pushed;
  final int pulled;
  final List<String> errors;
  final bool notAuthenticated;
  final bool offline;
  final bool busy;

  SyncResult({
    required this.pushed,
    required this.pulled,
    required this.errors,
  })  : notAuthenticated = false,
        offline = false,
        busy = false;

  SyncResult.notAuthenticated()
      : pushed = 0,
        pulled = 0,
        errors = const ['User not authenticated.'],
        notAuthenticated = true,
        offline = false,
        busy = false;

  SyncResult.offline()
      : pushed = 0,
        pulled = 0,
        errors = const ['Device is offline.'],
        notAuthenticated = false,
        offline = true,
        busy = false;

  SyncResult.busy()
      : pushed = 0,
        pulled = 0,
        errors = const [],
        notAuthenticated = false,
        offline = false,
        busy = true;

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => !hasErrors && !notAuthenticated && !offline && !busy;

  @override
  String toString() =>
      'SyncResult(pushed: $pushed, pulled: $pulled, errors: $errors)';
}
