class ApiConstants {
  static const String baseUrl = 'https://www.sadean.jojatech.biz.id/api/';
  static const String version = '1.1';

  // Endpoints
  static const String login = '${baseUrl}login';
  static const String checkSubscribe = '${baseUrl}user/subscriptions';
  static const String backupUpload = '${baseUrl}backups';
  static const String backupDownload = '${baseUrl}backups/latest/download';
}