import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/providers.dart';
import 'data/auth_repository.dart';

enum AuthStatus { checking, unauthenticated, authenticated, submitting, error }

class AuthState {
  const AuthState({required this.status, this.phone, this.errorMessage});

  const AuthState.checking() : this(status: AuthStatus.checking);

  const AuthState.unauthenticated({String? phone})
    : this(status: AuthStatus.unauthenticated, phone: phone);

  const AuthState.authenticated({String? phone})
    : this(status: AuthStatus.authenticated, phone: phone);

  const AuthState.submitting({String? phone})
    : this(status: AuthStatus.submitting, phone: phone);

  const AuthState.error(String message, {String? phone})
    : this(status: AuthStatus.error, errorMessage: message, phone: phone);

  final AuthStatus status;
  final String? phone;
  final String? errorMessage;

  bool get isLoggedIn => status == AuthStatus.authenticated;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref, this._repository) : super(const AuthState.checking()) {
    Future<void>.microtask(checkSession);
  }

  final Ref _ref;
  final AuthRepository _repository;
  final StreamController<AuthState> _changes =
      StreamController<AuthState>.broadcast();

  @override
  Stream<AuthState> get stream => _changes.stream;

  @override
  set state(AuthState value) {
    super.state = value;
    _changes.add(value);
  }

  Future<void> checkSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    state = AuthState.authenticated(phone: session.user.phone);
  }

  Future<void> requestOtp(String phone) async {
    state = AuthState.submitting(phone: phone);
    try {
      await _repository.requestOtp(phone);
      state = AuthState.unauthenticated(phone: phone);
    } catch (error) {
      state = AuthState.error(error.toString(), phone: phone);
    }
  }

  Future<bool> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    state = AuthState.submitting(phone: phone);
    try {
      await _repository.signInWithPassword(phone: phone, password: password);
      state = AuthState.authenticated(phone: phone);
      return true;
    } catch (error) {
      state = AuthState.error(error.toString(), phone: phone);
      return false;
    }
  }

  Future<bool> signUpWithPassword({
    required String fullName,
    required String phone,
    required String password,
    String? email,
  }) async {
    state = AuthState.submitting(phone: phone);
    try {
      await _repository.signUpWithPassword(
        fullName: fullName,
        phone: phone,
        password: password,
        email: email,
      );
      state = AuthState.authenticated(phone: phone);
      return true;
    } catch (error) {
      state = AuthState.error(error.toString(), phone: phone);
      return false;
    }
  }

  Future<bool> verifyOtp({required String phone, required String otp}) async {
    state = AuthState.submitting(phone: phone);
    try {
      await _repository.verifyOtp(phone: phone, otp: otp);
      state = AuthState.authenticated(phone: phone);
      return true;
    } catch (error) {
      state = AuthState.error(error.toString(), phone: phone);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _ref.read(notificationServiceProvider).clearToken();
    } catch (_) {}
    await _repository.signOut();
    state = const AuthState.unauthenticated();
  }

  @override
  void dispose() {
    _changes.close();
    super.dispose();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(authTokenStorageProvider),
  ),
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref, ref.watch(authRepositoryProvider)),
);
