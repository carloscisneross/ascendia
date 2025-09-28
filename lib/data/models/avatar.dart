enum AvatarTier { free, premium }
enum AvatarGender { male, female, unknown }

class Avatar {
  final String id;
  final String path;
  final AvatarTier tier;
  final AvatarGender gender;
  final String? label;

  const Avatar({
    required this.id,
    required this.path,
    required this.tier,
    required this.gender,
    this.label,
  });
}
