import 'dart:async';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'api_constant.dart';
import 'app_exception.dart';

class ApiProvider extends GetxService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        body: {"email": email, "password": password},
      );
      return jsonDecode(_processResponse(response));
    } on SocketException catch (exception) {
      throw Exception('No Internet connection');
    } on TimeoutException catch (exception) {
      throw Exception('API not responded in time');
    } on BadRequestException catch (e) {
      throw Exception(e.message);
    } catch (exception) {
      throw Exception(exception.toString());
    }
  }

  dynamic _processResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 400:
      case 401:
      case 404:
        var responseJson = utf8.decode(response.bodyBytes);
        return responseJson;
      case 403:
        throw UnAuthorizedException(
            utf8.decode(response.bodyBytes), response.request!.url.toString());
      case 422:
        throw BadRequestException(
            utf8.decode(response.bodyBytes), response.request!.url.toString());
      case 500:
        throw BadRequestException(
            utf8.decode(response.bodyBytes), response.request!.url.toString());
      default:
        throw FetchDataException(
            'Error occured with code : ${response.statusCode}',
            response.request!.url.toString());
    }
  }
}
