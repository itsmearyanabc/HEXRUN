abstract class Failure {
  final String message;
  const Failure(this.message);

  factory Failure.server({required String message}) = ServerFailure;
  factory Failure.network({required String message}) = NetworkFailure;
  factory Failure.auth({required String message}) = AuthFailure;
  factory Failure.gps({required String message}) = GpsFailure;
  factory Failure.permission({required String message}) = PermissionFailure;
  factory Failure.cheat({required String message}) = CheatFailure;
  factory Failure.unknown({required String message}) = UnknownFailure;
}

class ServerFailure extends Failure { const ServerFailure({required String message}) : super(message); }
class NetworkFailure extends Failure { const NetworkFailure({required String message}) : super(message); }
class AuthFailure extends Failure { const AuthFailure({required String message}) : super(message); }
class GpsFailure extends Failure { const GpsFailure({required String message}) : super(message); }
class PermissionFailure extends Failure { const PermissionFailure({required String message}) : super(message); }
class CheatFailure extends Failure { const CheatFailure({required String message}) : super(message); }
class UnknownFailure extends Failure { const UnknownFailure({required String message}) : super(message); }