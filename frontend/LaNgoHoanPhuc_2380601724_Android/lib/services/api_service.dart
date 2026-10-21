import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class ApiService {
  static const Duration timeoutDuration = Duration(seconds: 25);

  static Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // 1. Đăng ký tài khoản qua email
  static Future<ApiResponse<void>> register(RegisterRequest request) async {
    final baseUrl = await AppConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/Auth/register');

    try {
      final response = await http
          .post(
            url,
            headers: await _getHeaders(requireAuth: false),
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeoutDuration);

      return _handleResponse<void>(response);
    } on SocketException {
      return ApiResponse<void>(
        status: false,
        message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc URL API!',
      );
    } on TimeoutException {
      return ApiResponse<void>(
        status: false,
        message: 'Hết thời gian chờ kết nối (Timeout). Vui lòng thử lại!',
      );
    } catch (e) {
      return ApiResponse<void>(
        status: false,
        message: 'Lỗi phát sinh: ${e.toString()}',
      );
    }
  }

  // 2. Đăng nhập (Username + Password) -> kích hoạt gửi OTP
  static Future<ApiResponse<void>> login(LoginRequest request) async {
    final baseUrl = await AppConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/Auth/login');

    try {
      final response = await http
          .post(
            url,
            headers: await _getHeaders(requireAuth: false),
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeoutDuration);

      return _handleResponse<void>(response);
    } on SocketException {
      return ApiResponse<void>(
        status: false,
        message: 'Không thể kết nối máy chủ API ($baseUrl)!',
      );
    } on TimeoutException {
      return ApiResponse<void>(
        status: false,
        message: 'Hết thời gian chờ kết nối. Vui lòng thử lại!',
      );
    } catch (e) {
      return ApiResponse<void>(
        status: false,
        message: 'Lỗi: ${e.toString()}',
      );
    }
  }

  // 3. Xác thực OTP
  static Future<ApiResponse<void>> verifyOtp(VerifyOtpRequest request) async {
    final baseUrl = await AppConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/Auth/verify-otp');

    try {
      final response = await http
          .post(
            url,
            headers: await _getHeaders(requireAuth: false),
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeoutDuration);

      return _handleResponse<void>(response);
    } on SocketException {
      return ApiResponse<void>(
        status: false,
        message: 'Không thể kết nối máy chủ!',
      );
    } on TimeoutException {
      return ApiResponse<void>(
        status: false,
        message: 'Hết thời gian chờ phản hồi OTP!',
      );
    } catch (e) {
      return ApiResponse<void>(
        status: false,
        message: 'Lỗi: ${e.toString()}',
      );
    }
  }

  // 4. CRUD - GET ALL USERS (Admin)
  static Future<ApiResponse<List<UserDto>>> getAllUsers() async {
    final baseUrl = await AppConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/AdminUsers');

    try {
      final response = await http
          .get(
            url,
            headers: await _getHeaders(requireAuth: true),
          )
          .timeout(timeoutDuration);

      return _handleResponse<List<UserDto>>(
        response,
        fromDataJson: (data) {
          if (data is List) {
            return data.map((item) => UserDto.fromJson(item as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );
    } on SocketException {
      return ApiResponse<List<UserDto>>(
        status: false,
        message: 'Lỗi kết nối mạng khi tải danh sách người dùng!',
      );
    } on TimeoutException {
      return ApiResponse<List<UserDto>>(
        status: false,
        message: 'Quá thời gian tải danh sách!',
      );
    } catch (e) {
      return ApiResponse<List<UserDto>>(
        status: false,
        message: 'Lỗi: ${e.toString()}',
      );
    }
  }

  // 5. CRUD - GET USER BY ID (Admin)
  static Future<ApiResponse<UserDto>> getUserById(String id) async {
    final baseUrl = await AppConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/AdminUsers/$id');

    try {
      final response = await http
          .get(
            url,
            headers: await _getHeaders(requireAuth: true),
          )
          .timeout(timeoutDuration);

      return _handleResponse<UserDto>(
        response,
        fromDataJson: (data) => UserDto.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse<UserDto>(
        status: false,
        message: 'Lỗi: ${e.toString()}',
      );
    }
  }

  // 6. CRUD - CREATE USER (Admin)
  static Future<ApiResponse<void>> createUser(RegisterRequest request) async {
    final baseUrl = await AppConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/AdminUsers');

    try {
      final response = await http
          .post(
            url,
            headers: await _getHeaders(requireAuth: true),
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeoutDuration);

      return _handleResponse<void>(response);
    } catch (e) {
      return ApiResponse<void>(
        status: false,
        message: 'Lỗi khi tạo người dùng: ${e.toString()}',
      );
    }
  }

  // 7. CRUD - UPDATE USER (Admin)
  static Future<ApiResponse<void>> updateUser(String id, UpdateUserRequest request) async {
    final baseUrl = await AppConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/AdminUsers/$id');

    try {
      final response = await http
          .put(
            url,
            headers: await _getHeaders(requireAuth: true),
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeoutDuration);

      return _handleResponse<void>(response);
    } catch (e) {
      return ApiResponse<void>(
        status: false,
        message: 'Lỗi khi cập nhật người dùng: ${e.toString()}',
      );
    }
  }

  // 8. CRUD - DELETE USER (Admin)
  static Future<ApiResponse<void>> deleteUser(String id) async {
    final baseUrl = await AppConfig.getBaseUrl();
    final url = Uri.parse('$baseUrl/AdminUsers/$id');

    try {
      final response = await http
          .delete(
            url,
            headers: await _getHeaders(requireAuth: true),
          )
          .timeout(timeoutDuration);

      return _handleResponse<void>(response);
    } catch (e) {
      return ApiResponse<void>(
        status: false,
        message: 'Lỗi khi xóa người dùng: ${e.toString()}',
      );
    }
  }

  // Helper to parse responses
  static ApiResponse<T> _handleResponse<T>(
    http.Response response, {
    T Function(dynamic)? fromDataJson,
  }) {
    try {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final bool status = decoded['status'] == true || (response.statusCode >= 200 && response.statusCode < 300 && decoded['status'] != false);
        String message = decoded['message']?.toString() ?? '';

        if (message.isEmpty) {
          if (decoded.containsKey('title')) {
            message = decoded['title'].toString();
          } else if (response.statusCode == 401) {
            message = 'Không có quyền truy cập (401 Unauthorized)!';
          } else if (response.statusCode == 403) {
            message = 'Truy cập bị từ chối (403 Forbidden)!';
          } else if (response.statusCode == 404) {
            message = 'Không tìm thấy dữ liệu (404 Not Found)!';
          } else {
            message = status ? 'Thành công' : 'Đã có lỗi xảy ra (${response.statusCode})';
          }
        }

        // If validation errors are present
        if (decoded.containsKey('errors') && decoded['errors'] != null) {
          final errs = decoded['errors'];
          if (errs is Map) {
            final List<String> errorMessages = [];
            errs.forEach((k, v) {
              if (v is List) {
                errorMessages.addAll(v.map((e) => e.toString()));
              } else {
                errorMessages.add('$k: $v');
              }
            });
            if (errorMessages.isNotEmpty) {
              message = '$message\n${errorMessages.join('\n')}';
            }
          } else if (errs is List) {
            final listStr = errs.map((e) {
              if (e is Map && e.containsKey('description')) return e['description'].toString();
              return e.toString();
            }).join('\n');
            message = '$message\n$listStr';
          }
        }

        return ApiResponse<T>.fromJson(
          {
            ...decoded,
            'status': status,
            'message': message,
          },
          fromDataJson: fromDataJson,
        );
      }

      return ApiResponse<T>(
        status: response.statusCode >= 200 && response.statusCode < 300,
        message: response.statusCode >= 200 && response.statusCode < 300
            ? 'Thao tác thành công!'
            : 'Mã phản hồi HTTP: ${response.statusCode}',
      );
    } catch (e) {
      return ApiResponse<T>(
        status: response.statusCode >= 200 && response.statusCode < 300,
        message: 'Phản hồi từ máy chủ: ${response.body}',
      );
    }
  }
}
