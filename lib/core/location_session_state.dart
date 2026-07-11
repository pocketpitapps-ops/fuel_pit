class LocationSessionState {
  static String? lastUserId;
  static bool askedForLocationInThisSession = false;

  static void resetForUser(String? userId) {
    if (userId == null) {
      // guest: vamos pedir sempre, não marcamos estado por user
      lastUserId = null;
      askedForLocationInThisSession = false;
      return;
    }

    if (lastUserId != userId) {
      // novo user autenticado → reset
      lastUserId = userId;
      askedForLocationInThisSession = false;
    }
  }
}
