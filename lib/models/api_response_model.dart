class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<ValidationError>? errors;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic)? fromJsonT,
      ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      errors: json['errors'] != null
          ? (json['errors'] as List)
          .map((e) => ValidationError.fromJson(e))
          .toList()
          : null,
    );
  }
}

class ValidationError {
  final String field;
  final String message;

  const ValidationError({
    required this.field,
    required this.message,
  });

  factory ValidationError.fromJson(Map<String, dynamic> json) {
    return ValidationError(
      field: json['field'] ?? '',
      message: json['message'] ?? '',
    );
  }
}