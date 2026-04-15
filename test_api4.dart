import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse(
      'https://api-demo.intranet.ikenas.com/api/events/69df83e2f8b3853fc40d71e0/respond');
  final payloads = [
    {'status': 'going'},
    {'status': 'not_going'},
    {'status': 'maybe'},
    {'status': 'interested'},
    {'status': 'ignored'},
    {'status': 'attending'},
    {'response': 'yes'},
    {'response': 'no'},
    {'participationStatus': 'yes'},
    {'status': 'participating'},
    {'status': 'not_participating'}
  ];

  for (var p in payloads) {
    final req = await HttpClient().putUrl(url);
    req.headers.set('Authorization',
        'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY5ZDRmOGE2NTNlOGE5MTdkNDU2MTAzOSIsInJvbGUiOiJzdHVkZW50IiwiaWF0IjoxNzc2Mjg3OTg2LCJleHAiOjE3NzY4OTI3ODZ9.x8A0uVE1GMVaJr-LCaBagCqAE0OqhLZn1V44DKRb_vA');
    req.headers.set('Content-Type', 'application/json');
    req.write(jsonEncode(p));

    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    if (res.statusCode == 200 || res.statusCode == 201) {
      print('SUCCESS with $p');
      print(body);
      break;
    } else {
      print('FAILED with $p: $body');
    }
  }
}
