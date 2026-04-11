import 'dart:convert';
import 'dart:io';

void main() async {
  var request = await HttpClient().getUrl(Uri.parse('https://api-demo.intranet.ikenas.com/news'));
  var response = await request.close();
  var responseBody = await response.transform(utf8.decoder).join();
  var data = jsonDecode(responseBody);
  
  if (data is Map && data['data'] is List && data['data'].isNotEmpty) {
    print('First news item:');
    print(JsonEncoder.withIndent('  ').convert(data['data'][0]));
  } else if (data is List && data.isNotEmpty) {
    print('First news item:');
    print(JsonEncoder.withIndent('  ').convert(data[0]));
  } else {
    print('Data: $data');
  }
}
