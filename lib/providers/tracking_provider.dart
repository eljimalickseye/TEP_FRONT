import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/vehicle_position.dart';
import '../services/api_service.dart';

class TrackingProvider extends ChangeNotifier {
  List<VehiclePosition> _positions = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  List<VehiclePosition> get positions => _positions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchPositions() async {
    try {
      final response = await ApiService.get('/tracking/positions');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _positions = data.map((p) => VehiclePosition.fromJson(p)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Tracking fetch error: $e');
    }
  }

  void startPolling() {
    _pollingTimer?.cancel();
    fetchPositions(); 
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchPositions();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<bool> updateDriverLocation(double lat, double lng, {double? speed, double? heading}) async {
    try {
      final response = await ApiService.post('/tracking/update', {
        'latitude': lat,
        'longitude': lng,
        'speed': speed,
        'heading': heading,
      });

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error uploading location: $e');
      return false;
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
