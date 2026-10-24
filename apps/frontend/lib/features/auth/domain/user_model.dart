class UserModel {
  final String id;
  final String firebaseUid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      firebaseUid:
          json['firebase_uid'] as String? ?? json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ??
          json['displayName'] as String? ??
          'Thành viên TienLo',
      photoUrl: json['avatar_url'] as String? ?? json['photoUrl'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': firebaseUid,
      'email': email,
      'display_name': displayName,
      'avatar_url': photoUrl,
      'created_at': createdAt,
    };
  }
}
