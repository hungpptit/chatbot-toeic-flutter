import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/core/theme/app_colors.dart';
import 'package:chat_toeic_app/features/auth/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authController = Get.find<AuthController>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Background Gradient Circles
          Positioned(
            top: -100,
            right: -100,
            child: _buildGradientCircle(AppColors.primary),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildGradientCircle(AppColors.primaryLight),
          ),
          
          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Header
                    const Icon(
                      Icons.auto_awesome,
                      size: 80,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TOEIC AI CHAT',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const Text(
                      'Chinh phục TOEIC cùng AI',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Login Card (Glassmorphism)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Mật khẩu',
                                icon: Icons.lock_outline,
                                isPassword: true,
                                obscureText: _obscurePassword,
                                onToggleVisibility: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  child: const Text(
                                    'Quên mật khẩu?',
                                    style: TextStyle(color: AppColors.accent),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              Obx(() => ElevatedButton(
                                onPressed: _authController.isLoading.value
                                    ? null
                                    : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: _authController.isLoading.value
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'ĐĂNG NHẬP',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              )),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'hoặc',
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Obx(() => OutlinedButton.icon(
                                onPressed: _authController.isLoading.value
                                    ? null
                                    : _handleGoogleLogin,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withOpacity(0.16)),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'G',
                                    style: TextStyle(
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                label: _authController.isLoading.value
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Text(
                                        'Tiếp tục với Google',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => Get.toNamed('/register'),
                          child: const Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientCircle(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Thông báo',
        'Vui lòng nhập đầy đủ email và mật khẩu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    final success = await _authController.login(email, password);
    if (success) {
      Get.offAllNamed('/home');
    }
  }

  void _handleGoogleLogin() async {
    final success = await _authController.loginWithGoogle();
    if (success) {
      Get.offAllNamed('/home');
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    int currentStep = 1; // 1: Input email, 2: Input OTP & New password
    bool isDialogLoading = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.bgCard,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                currentStep == 1 ? 'Quên mật khẩu' : 'Đặt lại mật khẩu',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (currentStep == 1) ...[
                        const Text(
                          'Nhập email của bạn để nhận mã OTP khôi phục mật khẩu.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.primary),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập email';
                            }
                            if (!value.contains('@')) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        Text(
                          'Mã OTP đã được gửi tới email:\n${emailController.text}',
                          style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: otpController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Mã OTP (6 chữ số)',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.textSecondary),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.primary),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập mã OTP';
                            }
                            if (value.trim().length != 6) {
                              return 'Mã OTP phải có 6 chữ số';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: newPasswordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu mới',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.primary),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập mật khẩu mới';
                            }
                            if (value.trim().length < 6) {
                              return 'Mật khẩu phải từ 6 ký tự trở lên';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: confirmPasswordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Xác nhận mật khẩu mới',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.white24),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.primary),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng xác nhận mật khẩu mới';
                            }
                            if (value != newPasswordController.text) {
                              return 'Mật khẩu xác nhận không khớp';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDialogLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isDialogLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isDialogLoading = true;
                            });
                            
                            try {
                              if (currentStep == 1) {
                                final success = await _authController.sendForgotPasswordOtp(emailController.text.trim());
                                if (success) {
                                  setState(() {
                                    currentStep = 2;
                                    isDialogLoading = false;
                                  });
                                } else {
                                  setState(() {
                                    isDialogLoading = false;
                                  });
                                }
                              } else {
                                final success = await _authController.resetPassword(
                                  emailController.text.trim(),
                                  otpController.text.trim(),
                                  newPasswordController.text.trim(),
                                );
                                if (success) {
                                  Navigator.of(context).pop(); // Close dialog
                                  Get.snackbar(
                                    'Thành công',
                                    'Đặt lại mật khẩu thành công. Hãy đăng nhập bằng mật khẩu mới.',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green.withOpacity(0.8),
                                    colorText: Colors.white,
                                    duration: const Duration(seconds: 4),
                                  );
                                } else {
                                  setState(() {
                                    isDialogLoading = false;
                                  });
                                }
                              }
                            } catch (e) {
                              setState(() {
                                isDialogLoading = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isDialogLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          currentStep == 1 ? 'Gửi OTP' : 'Xác nhận',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
