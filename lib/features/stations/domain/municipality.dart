class Municipality {
  final String district;
  final String municipality;

  Municipality({required this.district, required this.municipality});

  factory Municipality.fromJson(Map<String, dynamic> json) {
    return Municipality(
      district: json['district'] as String,
      municipality: json['municipality'] as String,
    );
  }
}
