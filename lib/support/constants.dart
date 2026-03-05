// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:dio/dio.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class Constants {
  static const String defaultUrl = "https://google.com";
  static const String apiKey = "sk-pfdDxy1BGJM4edj1TZxHM3thHDbiH";


  static const Color grey1 = Color.fromARGB(26, 158, 158, 158);
  static const Color blue1 = Color.fromARGB(237, 174, 228, 255);

  static bool isDownloadableFile(String url) {
    return url.endsWith(".pdf") ||
        url.endsWith(".docx") ||
        url.endsWith(".pptx") ||
        url.endsWith(".xlsx");
  }

  static String getValidUrl(String url) {
    if (url.startsWith("https://") || url.startsWith("http://")) {
      return url;
    }
    return "https://$url";
  }

  static String googleUrl(String key) {
    return "https://www.google.com/search?q=$key";
  }

  static Future<bool> isValidWebSite(String url) async {
    try {
      final response = await http
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 2));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> downloadFile(String url) async {
    final status = await Permission.storage.request();
    // final status = await PermissionRequest.storage.request();
    if (!status.isGranted) return null;

    final dir = await getDownloadsDirectory();
    final fileName = url.split('/').last;
    final filePath = "${dir?.path}/$fileName";

    await Dio().download(url, filePath);

    return filePath;
  }
}

class BrowserTab {
  InAppWebViewController? controller;
  WebUri url;
  WebUri? currentUrl;

  BrowserTab({required this.url});
}
