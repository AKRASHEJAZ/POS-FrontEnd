class CustomerModel {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final bool isWalkIn;
  final DateTime? createdAt;

  const CustomerModel({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.isWalkIn = false,
    this.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      isWalkIn: json['isWalkIn'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

