/// Expected API error codes for special condition branching
class ExpectedAPIErrorCode {
  ExpectedAPIErrorCode._();

  /// V3 user not found
  static const int v3UserNotFound = 600;

  /// User not authorized (not registered for email login)
  static const int userNotAuthorized = 602;

  /// Email already in use
  static const int emailAlreadyInUse = 606;

  /// User not registered (SNS login - registration required)
  static const int notRegistered = 618;

  /// Password not set
  static const int notSetPassword = 619;

  /// Insufficient UTXO
  static const int insufficientUtxo = 1000;
}
