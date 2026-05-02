import 'package:flutter/material.dart';

enum BundleCategory { city, theme }

/// A purchasable location pack. The server is the source of truth for
/// `slug` and `locationCount`; visual styling (`accentColor`, `icon`) is
/// resolved client-side from `accentHex` / `iconKey`.
class Bundle {
  const Bundle({
    required this.slug,
    required this.title,
    required this.tagline,
    required this.priceDisplay,
    required this.locationCount,
    required this.category,
    required this.accentColor,
    required this.icon,
    this.isPlaceholder = false,
  });

  final String slug;
  final String title;
  final String tagline;
  final String priceDisplay;
  final int locationCount;
  final BundleCategory category;
  final Color accentColor;
  final IconData icon;

  /// Coming-soon placeholder rows are rendered alongside real bundles
  /// to make the storefront feel populated. Tap on a placeholder shows a
  /// "coming soon" sheet instead of the real detail screen.
  final bool isPlaceholder;
}

class BundleLocation {
  const BundleLocation({
    required this.name,
    required this.sampleRoles,
    required this.totalRoles,
  });

  final String name;
  final List<String> sampleRoles;
  final int totalRoles;
}

class BundleDetail {
  const BundleDetail({required this.bundle, required this.locations});

  final Bundle bundle;
  final List<BundleLocation> locations;
}
