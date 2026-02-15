class Config {
  // Production URL on Render
  static const String baseUrl = "https://wasalni-1.onrender.com";
  
  // For Local XAMPP Testing:
  // static const String baseUrl = "http://10.0.2.2/wasalni/backend"; 

  static Map<String, String> get headers => {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Accept": "application/json",
    "X-Requested-With": "XMLHttpRequest",
    "Cache-Control": "no-cache",
  };

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    return "$baseUrl/$path";
  }
}
