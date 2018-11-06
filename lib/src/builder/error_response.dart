import 'dart:convert';

/// [Builder] response data.

import 'package:shelf/shelf.dart';

class ErrorResponse {
  int statusCode;
  String message;

  ErrorResponse([this.statusCode, this.message]);

  ErrorResponse.notAuthorized()
      : statusCode = 401,
        message = 'Not authorized.';

  ErrorResponse.tooManyRequests()
      : statusCode = 429,
        message = 'Too many requests.';

  ErrorResponse.missingArguments(Map<String, dynamic> requiredArguments) : statusCode = 422 {
    List<String> data = [];

    requiredArguments.forEach((String argument, dynamic value) {
      if (value == null) {
        data.add(argument);
      }
    });

    message = 'Missing arguments ${data.join(', ')}.';
  }

  ErrorResponse.wrongArgumentFormat(List<String> wrongArguments) : statusCode = 422 {
    message = 'Wrong arguments ${wrongArguments.join(', ')}.';
  }

  Map<String, dynamic> asMap() {
    return {'statusCode': statusCode, 'errorMessage': message};
  }

  Response getResponse() {
    return new Response(statusCode, body: JSON.encode(asMap()), headers: {'content-type': 'application/json'});
  }
}
