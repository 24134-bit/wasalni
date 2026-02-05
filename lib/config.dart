class Config {
  // Production URL for InfinityFree
  static const String baseUrl = "https://wasalniapp.great-site.net/backend";

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    return "$baseUrl/$path";
  }
}
