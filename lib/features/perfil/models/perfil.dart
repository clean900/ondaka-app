/// Modelo do utilizador autenticado.
/// Reflecte o que retorna GET /api/user.
class Perfil {
  final int id;
  final String name;
  final String email;
  final String? telefone;
  final int empresaGestoraId;
  final String estado;
  final List<String> roles;
  final String locale;
  final bool mustChangePassword;
  final String? fotoPath;

  const Perfil({
    required this.id,
    required this.name,
    required this.email,
    this.telefone,
    required this.empresaGestoraId,
    required this.estado,
    required this.roles,
    required this.locale,
    required this.mustChangePassword,
    this.fotoPath,
  });

  /// Primeiro role para mostrar como "cargo" no UI.
  String get rolePrincipal => roles.isNotEmpty ? roles.first : '';

  /// Iniciais para avatar (até 2 letras).
  String get iniciais {
    final partes = name.trim().split(RegExp(r'\s+'));
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes.last[0]).toUpperCase();
  }

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      telefone: json['telefone'] as String?,
      empresaGestoraId: json['empresa_gestora_id'] as int,
      estado: json['estado'] as String? ?? 'activo',
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      locale: json['locale'] as String? ?? 'pt_AO',
      mustChangePassword: (json['must_change_password'] as bool?) ?? false,
      fotoPath: json['foto_path'] as String?,
    );
  }

  Perfil copyWith({
    String? name,
    String? email,
    String? telefone,
    String? locale,
    bool? mustChangePassword,
  }) {
    return Perfil(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      empresaGestoraId: empresaGestoraId,
      estado: estado,
      roles: roles,
      locale: locale ?? this.locale,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      fotoPath: fotoPath,
    );
  }
}
