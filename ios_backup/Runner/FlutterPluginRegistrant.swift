import UIKit
import Flutter

@objc
class FlutterPluginRegistrant {
  @objc
  static func registerPlugins(with registry: FlutterPluginRegistry) {
    // These are the plugins used in the project based on pubspec.yaml
    // Camera plugin
    if let cameraPlugin = FLTCameraPlugin(registry: registry) {
      registry.register(cameraPlugin, withId: "plugins.flutter.io/camera")
    }

    // Image picker plugin
    if let imagePickerPlugin = FlutterImagePickerPlugin(registry: registry) {
      registry.register(imagePickerPlugin, withId: "plugins.flutter.io/image_picker")
    }

    // Permission handler plugin
    if let permissionHandlerPlugin = FLTPermissionHandlerPlugin(registry: registry) {
      registry.register(permissionHandlerPlugin, withId: "baseflow/permission_handler")
    }

    // Supabase Flutter plugin
    if let supabaseFlutterPlugin = FLTSupabaseFlutterPlugin(registry: registry) {
      registry.register(supabaseFlutterPlugin, withId: "supabase_flutter")
    }

    // In-app purchase plugin
    if let inAppPurchasePlugin = FlutterInAppPurchasePlugin(registry: registry) {
      registry.register(inAppPurchasePlugin, withId: "plugins.flutter.io/in_app_purchase")
    }

    // PDF plugin
    if let pdfPlugin = FLTPDFPlugin(registry: registry) {
      registry.register(pdfPlugin, withId: "plugins.flutter.io/pdf")
    }

    // Printing plugin
    if let printingPlugin = FlutterPrintingPlugin(registry: registry) {
      registry.register(printingPlugin, withId: "plugins.flutter.io/printing")
    }

    // Package info plus plugin
    if let packageInfoPlusPlugin = FlutterPackageInfoPlusPlugin(registry: registry) {
      registry.register(packageInfoPlusPlugin, withId: "baseflow/package_info_plus")
    }

    // Shared preferences plugin
    if let sharedPreferencesPlugin = FlutterSharedPreferencesPlugin(registry: registry) {
      registry.register(sharedPreferencesPlugin, withId: "plugins.flutter.io/shared_preferences")
    }

    // URL launcher plugin
    if let urlLauncherPlugin = FlutterURLLauncherPlugin(registry: registry) {
      registry.register(urlLauncherPlugin, withId: "plugins.flutter.io/url_launcher")
    }

    // Flutter local notifications plugin
    if let localNotificationsPlugin = FlutterLocalNotificationsPlugin(registry: registry) {
      registry.register(localNotificationsPlugin, withId: "plugins.flutter.io/flutter_local_notifications")
    }

    // Share plus plugin
    if let sharePlusPlugin = FlutterSharePlusPlugin(registry: registry) {
      registry.register(sharePlusPlugin, withId: "plugins.flutter.io/share_plus")
    }

    // Provider plugin (no native implementation needed for Dart-only plugins)
    // Google fonts plugin (no native implementation needed for Dart-only plugins)
    // Intl plugin (no native implementation needed for Dart-only plugins)
    // Flutter dotenv plugin (no native implementation needed for Dart-only plugins)
    // Flutter timezone plugin (no native implementation needed for Dart-only plugins)
    // Timezone plugin (no native implementation needed for Dart-only plugins)
    // CSV plugin (no native implementation needed for Dart-only plugins)
    // JS plugin (no native implementation needed for Dart-only plugins)
  }
}