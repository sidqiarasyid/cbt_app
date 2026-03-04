class SchoolProfileModel {
  final int id;
  final String schoolName;
  final String? npsn;
  final String? address;
  final String? city;
  final String? province;
  final String? postalCode;
  final String? phone;
  final String? email;
  final String? website;
  final String? logoUrl;
  final String? principalName;
  final String? schoolLevel;
  final String? accreditation;

  SchoolProfileModel({
    required this.id,
    required this.schoolName,
    this.npsn,
    this.address,
    this.city,
    this.province,
    this.postalCode,
    this.phone,
    this.email,
    this.website,
    this.logoUrl,
    this.principalName,
    this.schoolLevel,
    this.accreditation,
  });

  factory SchoolProfileModel.fromJson(Map<String, dynamic> json) {
    return SchoolProfileModel(
      id: json['id'] ?? 1,
      schoolName: json['school_name'] ?? 'CBT App',
      npsn: json['npsn'],
      address: json['address'],
      city: json['city'],
      province: json['province'],
      postalCode: json['postal_code'],
      phone: json['phone'],
      email: json['email'],
      website: json['website'],
      logoUrl: json['logo_url'],
      principalName: json['principal_name'],
      schoolLevel: json['school_level'],
      accreditation: json['accreditation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_name': schoolName,
      'npsn': npsn,
      'address': address,
      'city': city,
      'province': province,
      'postal_code': postalCode,
      'phone': phone,
      'email': email,
      'website': website,
      'logo_url': logoUrl,
      'principal_name': principalName,
      'school_level': schoolLevel,
      'accreditation': accreditation,
    };
  }

  /// Fallback instance when API is unavailable
  static SchoolProfileModel fallback() {
    return SchoolProfileModel(id: 1, schoolName: 'CBT App');
  }
}
