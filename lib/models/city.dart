class City {
  final String name;
  final String country;
  final String timezone;
  final double? lat;
  final double? lng;

  City({
    required this.name,
    required this.country,
    required this.timezone,
    this.lat,
    this.lng,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    // Estrai il timezone correttamente
    String timezoneId = 'UTC';
    if (json['timezone'] != null) {
      if (json['timezone'] is String) {
        timezoneId = json['timezone'];
      } else if (json['timezone'] is Map) {
        timezoneId = json['timezone']['timeZoneId'] ?? 'UTC';
      }
    }

    return City(
      name: json['name']?.toString() ?? json['toponymName']?.toString() ?? '',
      country: json['countryName']?.toString() ?? json['country']?.toString() ?? '',
      timezone: timezoneId,
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
    );
  }

  String get displayName => '$name, $country';

  bool isSameAs(String otherName, String otherTimezone) {
    return name == otherName && timezone == otherTimezone;
  }
}