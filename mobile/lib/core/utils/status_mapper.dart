import 'package:flutter/material.dart';

class StatusMapper {
  static String getOrderStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Onay Bekliyor';
      case 'SHIPPED':
        return 'Kargoda / Yolda';
      case 'DELIVERED':
        return 'Teslim Edildi';
      case 'CANCELLED':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  static Color getOrderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'SHIPPED':
        return Colors.blue;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String getSwapStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Teklif Bekliyor';
      case 'ACCEPTED':
        return 'Kabul Edildi';
      case 'REJECTED':
        return 'Reddedildi';
      case 'WORKSHOP':
        return 'Atölye İncelemesinde';
      case 'COMPLETED':
        return 'Takas Tamamlandı';
      case 'CANCELLED':
        return 'İptal Edildi';
      default:
        return status;
    }
  }
}
