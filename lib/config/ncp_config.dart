import 'package:flutter_dotenv/flutter_dotenv.dart';

class NcpConfig {
  // NCP Object Storage 설정
  static final String accessKeyId = dotenv.env['NCP_ACCESS_KEY'] ?? '';
  static String secretAccessKey = dotenv.env['NCP_SECRET_KEY'] ?? '';
  static String endpoint = 'https://kr.object.ncloudstorage.com';
  static String region = 'kr-standard';
  
  // 버킷 이름
  static String imageBucket = 'uploadimage';
  static String fileBucket = 'uploadfile';
  static String vodBucket = 'startoo-vod';
}

