import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import '../config/ncp_config.dart';

class NcpStorageService {
  final Dio _dio = Dio();
  
  // 파일 업로드 (이미지)
  Future<String?> uploadImage(File file, String fileName) async {
    try {
      final objectKey = _generateObjectKey(fileName);
      // Path-style: endpoint/bucket/object-key
      final url = '${NcpConfig.endpoint}/${NcpConfig.imageBucket}/$objectKey';
      
      // 파일 읽기
      final fileBytes = await file.readAsBytes();
      final contentType = _getContentType(file.path);
      
      // AWS Signature V4 생성 (Path-style: 버킷 이름을 URI에 포함)
      final headers = _generateHeaders(
        method: 'PUT',
        bucket: NcpConfig.imageBucket,
        objectKey: objectKey,
        contentType: contentType,
        contentLength: fileBytes.length,
        payload: fileBytes,
        usePathStyle: true, // Path-style 사용
      );
      
      // 파일 업로드
      final response = await _dio.put(
        url,
        data: fileBytes,
        options: Options(
          headers: headers,
          contentType: contentType,
        ),
      );
      
      if (response.statusCode == 200) {
        return '/${NcpConfig.imageBucket}/$objectKey';
      }
      
      return null;
    } catch (e) {
      print('NCP Storage 업로드 에러: $e');
      return null;
    }
  }
  
  // 파일 업로드 (일반 파일)
  Future<String?> uploadFile(File file, String fileName) async {
    try {
      final objectKey = _generateObjectKey(fileName);
      // Path-style: endpoint/bucket/object-key
      final url = '${NcpConfig.endpoint}/${NcpConfig.fileBucket}/$objectKey';
      
      // 파일 읽기
      final fileBytes = await file.readAsBytes();
      final contentType = _getContentType(file.path);
      
      // AWS Signature V4 생성 (Path-style: 버킷 이름을 URI에 포함)
      final headers = _generateHeaders(
        method: 'PUT',
        bucket: NcpConfig.fileBucket,
        objectKey: objectKey,
        contentType: contentType,
        contentLength: fileBytes.length,
        payload: fileBytes,
        usePathStyle: true, // Path-style 사용
      );
      
      // 파일 업로드
      final response = await _dio.put(
        url,
        data: fileBytes,
        options: Options(
          headers: headers,
          contentType: contentType,
        ),
      );
      
      if (response.statusCode == 200) {
        return '/${NcpConfig.fileBucket}/$objectKey';
      }
      
      return null;
    } catch (e) {
      print('NCP Storage 업로드 에러: $e');
      return null;
    }
  }
  
  // Object Key 생성 (/연도/월/파일명)
  String _generateObjectKey(String fileName) {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    
    // 파일명에 타임스탬프 추가하여 중복 방지
    final timestamp = now.millisecondsSinceEpoch;
    final extension = path.extension(fileName);
    final nameWithoutExt = path.basenameWithoutExtension(fileName);
    final uniqueFileName = '${nameWithoutExt}_$timestamp$extension';
    
    return '$year/$month/$uniqueFileName';
  }
  
  // Content-Type 결정
  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
  
  // AWS Signature V4 헤더 생성 (S3 호환)
  Map<String, String> _generateHeaders({
    required String method,
    required String bucket,
    required String objectKey,
    required String contentType,
    required int contentLength,
    required List<int> payload,
    bool usePathStyle = true, // Path-style vs Virtual-hosted-style
  }) {
    final now = DateTime.now().toUtc();
    final dateStamp = _formatDateStamp(now);
    final amzDate = _formatAmzDate(now);
    
    // Object Key URL 인코딩 (슬래시는 인코딩하지 않음)
    final encodedObjectKey = _encodeUriPath(objectKey);
    final encodedBucket = _encodeUriPath(bucket);
    
    // Canonical Request
    // Path-style: /bucket/object-key
    // Virtual-hosted-style: /object-key
    final canonicalUri = usePathStyle 
        ? '/$encodedBucket/$encodedObjectKey'
        : '/$encodedObjectKey';
    final canonicalQueryString = '';
    
    // Payload Hash (x-amz-content-sha256에 사용)
    final payloadHash = sha256.convert(payload).toString();
    
    // Canonical Headers (소문자로 정렬, 콜론 뒤 공백 없음)
    // NCP Object Storage 필수 헤더: x-amz-content-sha256
    final headers = <String, String>{
      'content-length': contentLength.toString(),
      'content-type': contentType,
      'host': _getHost(),
      'x-amz-acl': 'public-read', // 공개 읽기 권한 설정
      'x-amz-date': amzDate,
      'x-amz-content-sha256': payloadHash,
    };
    
    // 헤더 정렬 (소문자 키 기준)
    final sortedHeaderKeys = headers.keys.toList()..sort();
    final canonicalHeaders = sortedHeaderKeys
        .map((key) => '$key:${headers[key]}')
        .join('\n') + '\n';
    
    // Signed Headers (소문자, 정렬)
    final signedHeaders = sortedHeaderKeys.join(';');
    
    final canonicalRequest = [
      method,
      canonicalUri,
      canonicalQueryString,
      canonicalHeaders,
      signedHeaders,
      payloadHash,
    ].join('\n');
    
    // 디버깅용 로그
    print('=== Canonical Request ===');
    print(canonicalRequest);
    print('========================');
    
    // String to Sign
    final algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/${NcpConfig.region}/s3/aws4_request';
    final stringToSign = [
      algorithm,
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');
    
    print('=== String to Sign ===');
    print(stringToSign);
    print('======================');
    
    // Signature
    final kSecret = utf8.encode('AWS4${NcpConfig.secretAccessKey}');
    final kDate = _hmacSha256(kSecret, dateStamp);
    final kRegion = _hmacSha256(kDate, NcpConfig.region);
    final kService = _hmacSha256(kRegion, 's3');
    final kSigning = _hmacSha256(kService, 'aws4_request');
    final signature = _hmacSha256(kSigning, stringToSign);
    
    // Authorization Header
    final signatureHex = signature.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    final authorization = '$algorithm '
        'Credential=${NcpConfig.accessKeyId}/$credentialScope, '
        'SignedHeaders=$signedHeaders, '
        'Signature=$signatureHex';
    
    return {
      'Host': _getHost(),
      'x-amz-date': amzDate,
      'x-amz-content-sha256': payloadHash, // NCP Object Storage 필수 헤더
      'x-amz-acl': 'public-read', // 공개 읽기 권한 설정
      'Authorization': authorization,
      'Content-Type': contentType,
      'Content-Length': contentLength.toString(),
    };
  }
  
  // URI 경로 인코딩 (슬래시는 인코딩하지 않음)
  String _encodeUriPath(String path) {
    return path.split('/').map((segment) {
      return Uri.encodeComponent(segment);
    }).join('/');
  }
  
  String _getHost() {
    final uri = Uri.parse(NcpConfig.endpoint);
    return uri.host;
  }
  
  String _formatDateStamp(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
  
  String _formatAmzDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '${year}${month}${day}T${hour}${minute}${second}Z';
  }
  
  List<int> _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }
}

