import 'dart:io';
import 'package:dio/dio.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/data/cubits/auth/google_signin_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// AUTH STATES
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthProgress extends AuthState {}

class Unauthenticated extends AuthState {}

class Authenticated extends AuthState {
  final bool isAuthenticated;

  Authenticated(this.isAuthenticated);
}

class AuthFailure extends AuthState {
  final String errorMessage;

  AuthFailure(this.errorMessage);
}

/// AUTH CUBIT
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if user is already authenticated
  void checkIsAuthenticated() {
    if (HiveUtils.isUserAuthenticated()) {
      emit(Authenticated(true));
    } else {
      emit(Unauthenticated());
    }
  }

  /// Google Sign-In Flow
  Future<void> signInWithGoogle() async {
    try {
      emit(AuthProgress());

      final User? user = await GoogleSignInHelper.signInWithGoogle();

      if (user != null) {
        HiveUtils.setFirebaseUser(user);
        emit(Authenticated(true));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthFailure("Google Sign-In failed: ${e.toString()}"));
    }
  }

  /// Update user data (via API)
  Future<Map<String, dynamic>> updateUserData(
    BuildContext context, {
    String? name,
    String? email,
    String? address,
    File? fileUserimg,
    String? fcmToken,
    String? notification,
    String? mobile,
    String? countryCode,
    int? personalDetail,
  }) async {
    Map<String, dynamic> parameters = {
      Api.name: name ?? '',
      Api.email: email ?? '',
      Api.address: address ?? '',
      Api.fcmId: fcmToken ?? '',
      Api.notification: notification ?? '',
      Api.mobile: mobile ?? '',
      Api.countryCode: countryCode ?? '',
      Api.personalDetail: personalDetail ?? 0,
    };

    if (fileUserimg != null) {
      parameters['profile'] = await MultipartFile.fromFile(fileUserimg.path);
    }

    try {
      final response =
          await Api.post(url: Api.updateProfileApi, parameter: parameters);

      if (!response[Api.error]) {
        HiveUtils.setUserData(response['data']);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Logout from Google and app
  Future<void> signOut(BuildContext context) async {
    try {
      await GoogleSignInHelper.signOut();
      HiveUtils.logoutUser(context, onLogout: () {});
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthFailure("Sign out failed: ${e.toString()}"));
    }
  }
}
