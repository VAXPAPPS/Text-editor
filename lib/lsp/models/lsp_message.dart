abstract class LSPMessage {
  final String jsonrpc = '2.0';

  Map<String, dynamic> toJson();
}

class RequestMessage extends LSPMessage {
  final int id;
  final String method;
  final dynamic params;

  RequestMessage({required this.id, required this.method, this.params});

  @override
  Map<String, dynamic> toJson() => {
    'jsonrpc': jsonrpc,
    'id': id,
    'method': method,
    if (params != null) 'params': params,
  };
}

class NotificationMessage extends LSPMessage {
  final String method;
  final dynamic params;

  NotificationMessage({required this.method, this.params});

  @override
  Map<String, dynamic> toJson() => {
    'jsonrpc': jsonrpc,
    'method': method,
    if (params != null) 'params': params,
  };
}

class ResponseMessage extends LSPMessage {
  final int? id;
  final dynamic result;
  final ResponseError? error;

  ResponseMessage({this.id, this.result, this.error});

  factory ResponseMessage.fromJson(Map<String, dynamic> json) {
    return ResponseMessage(
      id: json['id'] as int?,
      result: json['result'],
      error: json['error'] != null
          ? ResponseError.fromJson(json['error'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'jsonrpc': jsonrpc,
    'id': id,
    if (result != null) 'result': result,
    if (error != null) 'error': error!.toJson(),
  };
}

class ResponseError {
  final int code;
  final String message;
  final dynamic data;

  ResponseError({required this.code, required this.message, this.data});

  factory ResponseError.fromJson(Map<String, dynamic> json) {
    return ResponseError(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    if (data != null) 'data': data,
  };
}
