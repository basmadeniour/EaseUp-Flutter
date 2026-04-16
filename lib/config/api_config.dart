import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConfig {
  // ✅ للويب (Chrome)
  static const String webBaseUrl = 'http://localhost:5293';
  
  // ✅ للأندرويد Emulator
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:5293';
  
  // ✅ للجهاز الحقيقي (غيري الـ IP حسب شبكتك)
  static const String realDeviceBaseUrl = 'http://192.168.1.100:5293';
  
  // ✅ API خارجي للاستبيانات (اختياري)
  static const String surveyApi = 'https://shrieky-stephan-uncontemned.ngrok-free.dev';
  
  // ✅ اختيار العنوان المناسب تلقائياً
  static String getBaseUrl() {
    if (kIsWeb) {
      return webBaseUrl;
    } else if (Platform.isAndroid) {
      // للتمييز بين Emulator والجهاز الحقيقي
      // يمكنكِ استخدام متغير بيئة أو تخزين اختيار المستخدم
      return androidEmulatorBaseUrl; // أو realDeviceBaseUrl
    } else if (Platform.isIOS) {
      return webBaseUrl; // iOS Simulator يستخدم localhost
    } else {
      return webBaseUrl; // Desktop
    }
  }
  
  // ✅ طريقة مبسطة للاستخدام
  static String get baseUrl => getBaseUrl();
  
  // ✅ طريقة للتبديل بين Emulator والجهاز الحقيقي يدوياً (اختياري)
  static bool useRealDevice = false; // غيري إلى true للجهاز الحقيقي
  
  static String get dynamicBaseUrl {
    if (kIsWeb) {
      return webBaseUrl;
    } else if (Platform.isAndroid) {
      return useRealDevice ? realDeviceBaseUrl : androidEmulatorBaseUrl;
    } else {
      return webBaseUrl;
    }
  }
}