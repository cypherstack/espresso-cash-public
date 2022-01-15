import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:solana/src/exceptions/http_exception.dart';
import 'package:solana/src/exceptions/json_rpc_exception.dart';

class JsonRpcClient {
  JsonRpcClient(
    this._url, {
    required Duration timeout,
  }) : _timeout = timeout;

  final String _url;
  final Duration _timeout;
  int _lastId = 1;

  /// Calls the [method] jsonrpc-2.0 method with [params] parameters
  Future<Map<String, dynamic>> request(
    String method, {
    List<dynamic>? params,
  }) async {
    final request = <String, dynamic>{
      'jsonrpc': '2.0',
      'id': (_lastId++).toString(),
      'method': method,
    };
    // If no parameters were specified, skip this field
    if (params != null) request['params'] = params;
    // Perform the POST request
    final http.Response response = await http
        .post(
      Uri.parse(_url),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(request),
    )
        .timeout(
      _timeout,
      onTimeout: () {
        throw TimeoutException('Timeout while calling $method');
      },
    );

    // Handle the response
    if (response.statusCode != 200) {
      throw HttpException(response.statusCode, response.body);
    } else {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['jsonrpc'] != '2.0') {
        throw const FormatException('invalid jsonrpc-2.0 response');
      }
      if (data['error'] != null) {
        throw JsonRpcException.fromJson(data['error'] as Map<String, dynamic>);
      }
      if (!data.containsKey('result')) {
        throw const FormatException(
            'object has no result field, invalid jsonrpc-2.0');
      }
      return data;
    }
  }
}
