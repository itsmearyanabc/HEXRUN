/// Custom exceptions for HexRun
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error occurred']);
  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network error occurred']);
  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Authentication error']);
  @override
  String toString() => 'AuthException: $message';
}

class GpsException implements Exception {
  final String message;
  const GpsException([this.message = 'GPS error']);
  @override
  String toString() => 'GpsException: $message';
}

class PermissionException implements Exception {
  final String message;
  const PermissionException([this.message = 'Permission denied']);
  @override
  String toString() => 'PermissionException: $message';
}

class CheatDetectedException implements Exception {
  final String message;
  const CheatDetectedException([this.message = 'Cheat detected']);
  @override
  String toString() => 'CheatDetectedException: $message';
}