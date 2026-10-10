import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// The signed-in mover customer profile returned by /api/v1/auth/me.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final String id;
  final String email;
  final String name;
  final String role;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: '${json['id']}',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  String get firstName {
    final trimmed = name.trim();
    final space = trimmed.indexOf(' ');
    return space == -1 ? trimmed : trimmed.substring(0, space);
  }
}

class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
    );
  }
}

/// Result of requesting an OTP code, including the delivery channels used,
/// how long the code stays valid, and (when developer preview is enabled) the
/// code itself.
class SendOtpResult {
  const SendOtpResult({
    required this.expiresIn,
    required this.channels,
    this.devCode,
  });

  final int expiresIn;
  final List<String> channels;
  final String? devCode;

  factory SendOtpResult.fromJson(Map<String, dynamic> json) {
    return SendOtpResult(
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 600,
      channels:
          (json['channels'] as List?)?.map((e) => '$e').toList() ??
              const <String>[],
      devCode: json['dev_code'] as String?,
    );
  }
}

/// Multi-factor challenge returned by /api/v1/auth/login when the account
/// requires a one-time code on top of the password. The [mfaToken] must be
/// exchanged for a token pair via /api/v1/auth/mfa/verify.
class MfaChallenge {
  const MfaChallenge({
    required this.mfaToken,
    required this.expiresIn,
    required this.channels,
    this.devCode,
  });

  final String mfaToken;
  final int expiresIn;
  final List<String> channels;
  final String? devCode;

  factory MfaChallenge.fromJson(Map<String, dynamic> json) {
    return MfaChallenge(
      mfaToken: json['mfa_token'] as String? ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 600,
      channels:
          (json['channels'] as List?)?.map((e) => '$e').toList() ??
              const <String>[],
      devCode: json['dev_code'] as String?,
    );
  }
}

/// Outcome of a password sign-in: either a finished token pair or a
/// multi-factor challenge the client still has to solve.
class LoginResult {
  const LoginResult._({this.tokens, this.mfaChallenge});

  const LoginResult.success(TokenPair tokens) : this._(tokens: tokens);

  const LoginResult.mfaRequired(MfaChallenge challenge)
      : this._(mfaChallenge: challenge);

  final TokenPair? tokens;
  final MfaChallenge? mfaChallenge;

  bool get requiresMfa => mfaChallenge != null;
}

/// Calls the marketgo-api auth endpoints.
class AuthService {
  AuthService({ApiClient? api}) : api = api ?? ApiClient();

  final ApiClient api;

  /// Signs in with email/password. The API answers either with a token pair
  /// or with `mfa_required`, in which case the challenge must be verified
  /// through [verifyMfa].
  Future<LoginResult> signIn(String email, String password) async {
    final data = await api.post(
      '/api/v1/auth/login',
      body: {'email': email, 'password': password},
    );
    if (data['mfa_required'] == true) {
      return LoginResult.mfaRequired(MfaChallenge.fromJson(data));
    }
    return LoginResult.success(TokenPair.fromJson(data));
  }

  /// Exchanges the pending MFA token and the received one-time code for a
  /// token pair. Errors arrive as `{error: "..."}` → [ApiException].
  Future<TokenPair> verifyMfa({
    required String mfaToken,
    required String code,
  }) async {
    final data = await api.post(
      '/api/v1/auth/mfa/verify',
      body: {'mfa_token': mfaToken, 'code': code},
    );
    return TokenPair.fromJson(data);
  }

  /// Requests a one-time code delivered over WhatsApp and/or email. The phone
  /// is sent as typed; the backend normalises it to international format.
  /// Movers sign in as `customer` on the shared auth endpoints.
  Future<SendOtpResult> sendOtp({
    required String phone,
    String? email,
    String? name,
    String role = 'customer',
  }) async {
    final data = await api.post(
      '/api/v1/auth/otp/send',
      body: <String, dynamic>{
        'phone': phone,
        'role': role,
        if (email != null && email.isNotEmpty) 'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );
    return SendOtpResult.fromJson(data);
  }

  /// Exchanges the received code for a token pair, creating the account on
  /// first sign-in for the given role.
  Future<TokenPair> verifyOtp({
    required String phone,
    required String code,
    String? name,
    String role = 'customer',
  }) async {
    final data = await api.post(
      '/api/v1/auth/otp/verify',
      body: <String, dynamic>{
        'phone': phone,
        'code': code,
        'role': role,
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );
    return TokenPair.fromJson(data);
  }

  Future<AuthUser> me(String accessToken) async {
    final data = await api.get(
      '/api/v1/auth/me',
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    final user = data['user'];
    if (user is Map<String, dynamic>) return AuthUser.fromJson(user);
    throw const ApiException('Unexpected profile payload');
  }

  Future<void> signOut(String accessToken, String refreshToken) async {
    await api.post(
      '/api/v1/auth/logout',
      headers: {'Authorization': 'Bearer $accessToken'},
      body: {'refresh_token': refreshToken},
    );
  }
}

/// Reactive auth state owned by the app shell.
class AuthModel extends ChangeNotifier {
  AuthModel({AuthService? service, ApiClient? api})
      : _service = service ?? AuthService(api: api),
        _api = api;

  final AuthService _service;
  final ApiClient? _api;

  AuthUser? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _loading = false;
  String? _error;
  MfaChallenge? _pendingMfa;

  AuthUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;

  /// Challenge waiting for a one-time code, set when the password sign-in
  /// was answered with `mfa_required` (null once verified or cancelled).
  MfaChallenge? get pendingMfa => _pendingMfa;

  String? get accessToken => _accessToken;

  ApiClient get api => _service.api;

  set error(String? value) {
    _error = value;
    notifyListeners();
  }

  /// Applies a freshly issued token pair: loads the profile and enters an
  /// authenticated online session (returns false and sets [error] when the
  /// profile cannot be loaded).
  Future<bool> _completeSignIn(TokenPair tokens) async {
    final user = await _service.me(tokens.accessToken);
    _api?.isOffline = false;
    _accessToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    _user = user;
    return true;
  }

  /// Password sign-in. Returns true when the session is established; when the
  /// account requires MFA it stores the challenge in [pendingMfa] and returns
  /// false without setting [error] — the login screen then pushes the code
  /// screen.
  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.signIn(email.trim(), password);
      final tokens = result.tokens;
      if (tokens == null) {
        _pendingMfa = result.mfaChallenge;
        return false;
      }
      _pendingMfa = null;
      return await _completeSignIn(tokens);
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Verifies the pending MFA challenge with the received code, then finishes
  /// the sign-in started by [signIn].
  Future<bool> verifyMfaCode(String code) async {
    final challenge = _pendingMfa;
    if (challenge == null) {
      _error = 'Your sign-in session expired. Please sign in again.';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final tokens = await _service.verifyMfa(
        mfaToken: challenge.mfaToken,
        code: code,
      );
      _pendingMfa = null;
      return await _completeSignIn(tokens);
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Discards a pending MFA challenge when the user leaves the code screen.
  void cancelMfa() {
    if (_pendingMfa == null) return;
    _pendingMfa = null;
    notifyListeners();
  }

  /// Requests an OTP code for the given phone. Loading/error state for the
  /// request lives on the OTP screen; the result carries the dev code.
  Future<SendOtpResult> sendOtp(String phone, {String? email}) {
    return _service.sendOtp(phone: phone, email: email, role: 'customer');
  }

  /// Completes phone sign-in: verifies the code, loads the profile and enters
  /// an authenticated session (same state transitions as [signIn]).
  Future<bool> signInWithOtp(String phone, String code) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final tokens =
          await _service.verifyOtp(phone: phone, code: code, role: 'customer');
      return await _completeSignIn(tokens);
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    final token = _accessToken;
    final refresh = _refreshToken;
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _error = null;
    notifyListeners();
    if (token != null && refresh != null) {
      try {
        await _service.signOut(token, refresh);
      } catch (_) {}
    }
  }
}