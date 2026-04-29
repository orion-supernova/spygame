/// Convex deployment URL.
///
/// Defaults to the project's hosted deployment so `flutter run` works out
/// of the box. Override at build time when needed:
///   flutter run --dart-define=CONVEX_URL=https://other-deployment
class AppConvexConfig {
  AppConvexConfig._();

  static const String _defaultDeploymentUrl =
      'https://spyfall-api.walhallaa.dpdns.org';

  static const String deploymentUrl = String.fromEnvironment(
    'CONVEX_URL',
    defaultValue: _defaultDeploymentUrl,
  );

  static bool get isConfigured => deploymentUrl.isNotEmpty;
}
