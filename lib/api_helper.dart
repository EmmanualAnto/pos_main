import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiHelper {
  static const String baseUrl = "http://localhost:5095/api/items";

  /// GET all items
  static Future<List<Map<String, dynamic>>> getItems() async {
    final res = await http.get(Uri.parse(baseUrl));
    if (res.statusCode == 200) {
      List data = jsonDecode(res.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception("Failed to load items: ${res.statusCode}");
    }
  }

  /// ADD new item
  static Future<Map<String, dynamic>?> addItem(
    Map<String, dynamic> item,
  ) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(item),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    }
    return null;
  }

  /// UPDATE item using id
  static Future<bool> updateItem(int id, Map<String, dynamic> item) async {
    final res = await http.put(
      Uri.parse("$baseUrl/$id"), // use id, not barcode
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(item),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      debugPrint("Update failed: ${res.statusCode} ${res.body}");
    }
    return res.statusCode == 200 || res.statusCode == 204;
  }

  /// DELETE item using id
  static Future<bool> deleteItem(int id) async {
    final res = await http.delete(Uri.parse("$baseUrl/$id")); // use id
    return res.statusCode == 200 || res.statusCode == 204;
  }
}
