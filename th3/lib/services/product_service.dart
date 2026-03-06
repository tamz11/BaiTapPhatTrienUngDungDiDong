import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductService {
  static const String _baseUrl = 'https://dummyjson.com/products?limit=0';
  static const Set<String> _electronicCategories = <String>{
    'smartphones',
    'laptops',
    'tablets',
    'mobile-accessories',
  };

  Future<List<Product>> fetchProducts({bool forceError = false}) async {
    try {
      if (forceError) {
        throw const SocketException('Simulated connection error');
      }

      final response = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        throw HttpException(
          'Server error: ${response.statusCode}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> body = switch (decoded) {
        List<dynamic> listBody => listBody,
        Map<String, dynamic> mapBody
            when mapBody['products'] is List<dynamic> =>
          mapBody['products'] as List<dynamic>,
        _ => throw const FormatException('Unexpected response schema'),
      };

        return body
          .map((dynamic item) => Product.fromJson(item as Map<String, dynamic>))
          .where((Product item) => _electronicCategories.contains(item.category))
          .toList();
    } on SocketException {
      throw Exception('Khong the ket noi mang. Vui long kiem tra Internet.');
    } on HttpException catch (error) {
      throw Exception('Loi tu server: ${error.message}');
    } on FormatException {
      throw Exception('Du lieu tra ve khong hop le.');
    } catch (_) {
      throw Exception('Da xay ra loi khong xac dinh.');
    }
  }
}
