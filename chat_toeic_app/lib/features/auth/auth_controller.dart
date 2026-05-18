import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';
import 'package:chat_toeic_app/core/utils/app_env.dart';
import 'package:chat_toeic_app/core/utils/storage_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  var user = Rxn<Map<String, dynamic>>();

  GoogleSignIn? _googleSignIn;

  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn(
      scopes: const ['email', 'profile'],
      clientId: AppEnv.googleClientId.isNotEmpty ? AppEnv.googleClientId : null,
    );
    return _googleSignIn!;
  }

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final token = await StorageService.getAccessToken();
    if (token != null) {
      isLoggedIn.value = true;
      fetchUserProfile();
    }
  }

  Future<void> fetchUserProfile() async {
    isLoading.value = true;
    try {
      print('Fetching user profile from /v1/auth/me...');
      final response = await DioClient.dio.get('/v1/auth/me');
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        user.value = response.data['data'];
        print('User profile updated: ${user.value}');
      } else {
        print('Failed to fetch profile: ${response.data}');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    try {
      final response = await DioClient.dio.post('/v1/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await StorageService.saveTokens(
          access: data['accessToken'],
          refresh: data['refreshToken'],
        );
        isLoggedIn.value = true;
        return true;
      }
    } catch (e) {
      Get.snackbar(
        'Đăng nhập thất bại',
        'Vui lòng kiểm tra lại email và mật khẩu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
    return false;
  }

  Future<bool> loginWithGoogle() async {
    isLoading.value = true;
    try {
      final account = await googleSignIn.signIn();
      if (account == null) {
        return false;
      }

      final auth = await account.authentication;
      final response = await DioClient.dio.post('/v1/auth/google', data: {
        'idToken': auth.idToken,
        'accessToken': auth.accessToken,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await StorageService.saveTokens(
          access: data['accessToken'],
          refresh: data['refreshToken'],
        );
        user.value = Map<String, dynamic>.from(data['user'] ?? {});
        isLoggedIn.value = true;
        return true;
      }
    } on DioException catch (e) {
      final dynamic data = e.response?.data;
      final message = data is Map
          ? (data['message'] ?? data['error'] ?? e.message)
          : e.message;
      final details = data is Map && data['details'] is List
          ? (data['details'] as List).join('\n')
          : '';

      debugPrint('Google login API error: ${e.response?.statusCode} $data');
      Get.snackbar(
        'Đăng nhập Google thất bại',
        [message, details].where((s) => s != null && s.toString().trim().isNotEmpty).join('\n'),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint('Google login error: $e');
      Get.snackbar(
        'Đăng nhập Google thất bại',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }

    return false;
  }

  Future<void> logout() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken != null) {
        // Gọi API logout để Server xóa Cookie
        await DioClient.dio.post('/v1/auth/logout', data: {
          'refreshToken': refreshToken,
        });
      }
    } catch (e) {
      print('Error during API logout: $e');
    } finally {
      try {
        await googleSignIn.signOut();
      } catch (_) {}
      // Luôn luôn xóa dữ liệu local dù API có lỗi hay không
      await StorageService.clearTokens();
      user.value = null;
      isLoggedIn.value = false;
      Get.offAllNamed('/login');
    }
  }
}
