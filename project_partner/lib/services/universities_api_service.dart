import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class UniversityService {
  static const _url =
      'http://universities.hipolabs.com/search?country=North+Macedonia';

  Future<List<String>> fetchFaculties() async {
    try {
      final response = await http.get(Uri.parse(_url));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final names = data
            .map((u) => u['name'] as String)
            .toSet()
            .toList()
          ..sort();
        return names;
      }
    } catch (_) {}

    return faculties;
  }
}