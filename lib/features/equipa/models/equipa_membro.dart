import 'package:flutter/material.dart';

/// Membro da equipa do condominio (user interno ou empresa prestadora).
class EquipaMembro {
  final int id;
  final String tipo; // 'user' ou 'empresa'
  final String nome;
  final String cargo;
  final String roleSlug;
  final String? telefone;
  final String inicial;

  EquipaMembro({
    required this.id,
    required this.tipo,
    required this.nome,
    required this.cargo,
    required this.roleSlug,
    this.telefone,
    required this.inicial,
  });

  bool get eUser => tipo == 'user';
  bool get eEmpresa => tipo == 'empresa';
  bool get temTelefone => telefone != null && telefone!.isNotEmpty;

  /// Cor associada ao role (visual no card).
  Color get corRole {
    switch (roleSlug) {
      case 'super-admin':
      case 'admin-empresa':
        return const Color(0xFFA855F7); // purple
      case 'gestor':
        return const Color(0xFF00D4FF); // cyan
      case 'administrador-condominio':
        return const Color(0xFFEC4899); // pink
      case 'funcionario':
        return const Color(0xFF10B981); // success/green
      case 'guarda':
        return const Color(0xFFF59E0B); // warning/amber
      case 'empresa-prestadora':
        return const Color(0xFF378ADD); // info/blue
      default:
        return const Color(0xFF6B7280); // grey
    }
  }

  /// Icone associado ao role.
  IconData get iconeRole {
    switch (roleSlug) {
      case 'super-admin':
      case 'admin-empresa':
        return Icons.admin_panel_settings;
      case 'gestor':
        return Icons.manage_accounts;
      case 'administrador-condominio':
        return Icons.apartment;
      case 'funcionario':
        return Icons.engineering;
      case 'guarda':
        return Icons.security;
      case 'empresa-prestadora':
        return Icons.business;
      default:
        return Icons.person;
    }
  }

  factory EquipaMembro.fromJson(Map<String, dynamic> json) {
    return EquipaMembro(
      id: json['id'] as int,
      tipo: json['tipo'] as String,
      nome: json['nome'] as String,
      cargo: json['cargo'] as String,
      roleSlug: json['role_slug'] as String,
      telefone: json['telefone'] as String?,
      inicial: json['inicial'] as String? ?? '?',
    );
  }
}
