import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/order_model.dart';
import '../../data/models/shipment_model.dart';
import '../../data/models/swap_model.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── SWAP BADGE

class SwapStatusBadge extends StatelessWidget {
  const SwapStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: _label,
      color: _color,
      icon: _icon,
    );
  }

  String get _label {
    switch (status) {
      case SwapStatuses.pendingReturnPriceDifference:
        return 'Fark Bekleniyor';
      case SwapStatuses.pendingApproval:
        return 'Onay Bekleniyor';
      case SwapStatuses.accepted:
        return 'Kabul Edildi';
      case SwapStatuses.rejected:
        return 'Reddedildi';
      case SwapStatuses.shipped:
        return 'Kargoda';
      case SwapStatuses.delivered:
        return 'Teslim Edildi';
      case SwapStatuses.completed:
        return 'Tamamlandı';
      case SwapStatuses.cancelled:
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  Color get _color {
    switch (status) {
      case SwapStatuses.pendingApproval:
      case SwapStatuses.pendingReturnPriceDifference:
        return AppColors.warning;
      case SwapStatuses.accepted:
      case SwapStatuses.shipped:
      case SwapStatuses.delivered:
        return AppColors.info;
      case SwapStatuses.completed:
        return AppColors.success;
      case SwapStatuses.rejected:
      case SwapStatuses.cancelled:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData? get _icon {
    switch (status) {
      case SwapStatuses.pendingApproval:
        return Icons.hourglass_empty_rounded;
      case SwapStatuses.pendingReturnPriceDifference:
        return Icons.currency_lira_rounded;
      case SwapStatuses.accepted:
        return Icons.check_circle_outline_rounded;
      case SwapStatuses.shipped:
        return Icons.local_shipping_rounded;
      case SwapStatuses.delivered:
        return Icons.inventory_2_rounded;
      case SwapStatuses.completed:
        return Icons.done_all_rounded;
      case SwapStatuses.rejected:
      case SwapStatuses.cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

// ── ORDER BADGE

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: _label,
      color: _color,
      icon: _icon,
    );
  }

  String get _label {
    switch (status) {
      case OrderStatuses.pending:
        return 'Beklemede';
      case OrderStatuses.shipped:
        return 'Kargoda';
      case OrderStatuses.delivered:
        return 'Teslim Edildi';
      case OrderStatuses.returnRequested:
        return 'İade Talebi';
      case OrderStatuses.returned:
        return 'İade Edildi';
      case OrderStatuses.cancelled:
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  Color get _color {
    switch (status) {
      case OrderStatuses.pending:
        return AppColors.warning;
      case OrderStatuses.shipped:
      case OrderStatuses.delivered:
        return AppColors.info;
      case OrderStatuses.returned:
      case OrderStatuses.cancelled:
      case OrderStatuses.returnRequested:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData? get _icon {
    switch (status) {
      case OrderStatuses.pending:
        return Icons.schedule_rounded;
      case OrderStatuses.shipped:
        return Icons.local_shipping_rounded;
      case OrderStatuses.delivered:
        return Icons.check_circle_outline_rounded;
      case OrderStatuses.returnRequested:
        return Icons.assignment_return_rounded;
      case OrderStatuses.returned:
      case OrderStatuses.cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

// ── SHIPMENT/CARGO BADGE

class ShipmentStatusBadge extends StatelessWidget {
  const ShipmentStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: _label,
      color: _color,
      icon: _icon,
    );
  }

  String get _label {
    switch (status) {
      case CargoStatuses.preparing:
        return 'Hazırlanıyor';
      case CargoStatuses.inTransit:
        return 'Yolda';
      case CargoStatuses.outForDelivery:
        return 'Dağıtıma Çıktı';
      case CargoStatuses.delivered:
        return 'Teslim Edildi';
      case CargoStatuses.failedAttempt:
        return 'Teslim Edilemedi';
      default:
        return status;
    }
  }

  Color get _color {
    switch (status) {
      case CargoStatuses.preparing:
        return AppColors.warning;
      case CargoStatuses.inTransit:
      case CargoStatuses.outForDelivery:
        return AppColors.info;
      case CargoStatuses.delivered:
        return AppColors.success;
      case CargoStatuses.failedAttempt:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData? get _icon {
    switch (status) {
      case CargoStatuses.preparing:
        return Icons.inventory_2_rounded;
      case CargoStatuses.inTransit:
        return Icons.local_shipping_rounded;
      case CargoStatuses.outForDelivery:
        return Icons.hail_rounded;
      case CargoStatuses.delivered:
        return Icons.done_all_rounded;
      case CargoStatuses.failedAttempt:
        return Icons.error_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

// ── WORK ORDER BADGE

class WorkOrderStatusBadge extends StatelessWidget {
  const WorkOrderStatusBadge({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return AppBadge(
      label: _label,
      color: _color,
      icon: _icon,
    );
  }

  String get _label {
    switch (status) {
      case WorkOrderStatuses.pending:
        return 'Bekliyor';
      case WorkOrderStatuses.inProgress:
        return 'İşleniyor';
      case WorkOrderStatuses.completed:
        return 'Tamamlandı';
      case WorkOrderStatuses.cancelled:
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  Color get _color {
    switch (status) {
      case WorkOrderStatuses.pending:
        return AppColors.warning;
      case WorkOrderStatuses.inProgress:
        return AppColors.info;
      case WorkOrderStatuses.completed:
        return AppColors.success;
      case WorkOrderStatuses.cancelled:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData? get _icon {
    switch (status) {
      case WorkOrderStatuses.pending:
        return Icons.schedule_rounded;
      case WorkOrderStatuses.inProgress:
        return Icons.build_circle_outlined;
      case WorkOrderStatuses.completed:
        return Icons.check_circle_outline_rounded;
      case WorkOrderStatuses.cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

abstract final class SwapStatuses {
  static const String pendingApproval = 'PENDING_APPROVAL';
  static const String pendingReturnPriceDifference = 'PENDING_RETURN_PRICE_DIFFERENCE';
  static const String accepted = 'ACCEPTED';
  static const String rejected = 'REJECTED';
  static const String shipped = 'SHIPPED';
  static const String delivered = 'DELIVERED';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
}

abstract final class OrderStatuses {
  static const String pending = 'PENDING';
  static const String shipped = 'SHIPPED';
  static const String delivered = 'DELIVERED';
  static const String returnRequested = 'RETURN_REQUESTED';
  static const String returned = 'RETURNED';
  static const String cancelled = 'CANCELLED';
}

abstract final class CargoStatuses {
  static const String preparing = 'PREPARING';
  static const String inTransit = 'IN_TRANSIT';
  static const String outForDelivery = 'OUT_FOR_DELIVERY';
  static const String delivered = 'DELIVERED';
  static const String failedAttempt = 'FAILED_ATTEMPT';
}

abstract final class WorkOrderStatuses {
  static const String pending = 'PENDING';
  static const String inProgress = 'IN_PROGRESS';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
}
