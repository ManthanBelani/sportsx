// Standalone probe: replicates the app's exact Dio configuration and
// runs the full avatar upload flow against the local API.
// Run: dart run tool/upload_probe.dart
import 'dart:io';

import 'package:dio/dio.dart';

Future<void> main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:8002/api/v1',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));

  // 1. Login
  final login = await dio.post('/auth/login', data: {
    'email': 'athlete@sportx.test',
    'password': 'password',
  });
  final token = login.data['token'] as String;
  dio.options.headers['Authorization'] = 'Bearer $token';
  print('1. LOGIN ok, token ${token.substring(0, 6)}...');

  // 2. Multipart upload (same shape as pickAndUploadMedia)
  final png = File('/tmp/kilo/avatar.png');
  if (!png.existsSync()) {
    stderr.writeln('missing /tmp/kilo/avatar.png');
    exit(1);
  }
  final form = FormData.fromMap({
    'file': await MultipartFile.fromFile(png.path, filename: 'avatar.png'),
    'media_type': 'photo',
  });
  final upload = await dio.post('/media/upload', data: form);
  final mediaId = upload.data['data']['id'] as int;
  print('2. UPLOAD ok -> media id $mediaId');

  // 3. Link to profile
  await dio.put('/me/profile', data: {
    'full_name': 'John Athlete',
    'date_of_birth': '2012-05-15',
    'gender': 'male',
    'skill_level': 'intermediate',
    'city_id': 1,
    'experience': 'Passionate cricketer with 3 years of experience',
    'photo_media_id': mediaId,
  });
  print('3. PROFILE LINK ok');

  // 4. Read back
  final profile = await dio.get('/me/profile');
  final photo = profile.data['data']['photo'];
  print('4. PROFILE READ -> photo id ${photo?['id']}, url ${photo?['url']}');

  // 5. Serve the file
  final img = await Dio().get('http://127.0.0.1:8002${photo['url']}');
  print('5. SERVE -> HTTP ${img.statusCode}, ${img.data.toString().length} bytes');

  print('ALL STEPS PASSED');
}
