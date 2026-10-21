class ApiResponse<T> {
  final bool status;
  final String message;
  final T? data;
  final String? token;
  final List<String>? roles;
  final dynamic errors;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
    this.token,
    this.roles,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? fromDataJson,
  }) {
    T? parsedData;
    if (json.containsKey('data') && json['data'] != null && fromDataJson != null) {
      parsedData = fromDataJson(json['data']);
    }

    List<String>? parsedRoles;
    if (json.containsKey('roles') && json['roles'] is List) {
      parsedRoles = (json['roles'] as List).map((e) => e.toString()).toList();
    }

    return ApiResponse<T>(
      status: json['status'] is bool ? json['status'] : true,
      message: json['message']?.toString() ?? '',
      data: parsedData,
      token: json['token']?.toString(),
      roles: parsedRoles,
      errors: json['errors'],
    );
  }
}
