import 'dart:convert';
import 'package:http/http.dart' as http;

class MindsetService {
  final String azureContainerUrl = 'https://solidevwebsitev3.blob.core.windows.net/mindset-fuel';

  Future<String> fetchRandomImageUrl() async {
    final response = await http.get(Uri.parse('$azureContainerUrl?restype=container&comp=list'));

    if (response.statusCode == 200) {
      final xml = response.body;
      // Parse the XML to get the list of blobs
      final regex = RegExp(r'<Url>(.*?)<\/Url>');
      final matches = regex.allMatches(xml).map((match) => match.group(1)).toList();
      matches.shuffle();
      return matches.isNotEmpty ? matches.first! : '';
    } else {
      throw Exception('Failed to load images');
    }
  }
}
