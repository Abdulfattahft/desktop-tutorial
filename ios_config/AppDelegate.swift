// المسار: ios/Runner/AppDelegate.swift
// استبدل الملف الموجود بهذا المحتوى

import Flutter
import UIKit
import Firebase
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // تهيئة Firebase قبل أي شيء
    FirebaseApp.configure()

    // تسجيل مستقبل الإشعارات (iOS 10+)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ربط رمز APNs بـ Firebase Messaging — بدونه لا تصل الإشعارات على iOS
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
}
