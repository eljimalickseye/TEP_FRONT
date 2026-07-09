import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/line.dart';
import '../models/trip.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';

class BookingProvider extends ChangeNotifier {
  List<Line> _lines = [];
  List<Trip> _trips = [];
  List<Ticket> _myTickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Line> get lines => _lines;
  List<Trip> get trips => _trips;
  List<Ticket> get myTickets => _myTickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchLines() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/lines');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _lines = data.map((l) => Line.fromJson(l)).toList();
      } else {
        _errorMessage = 'Erreur lors de la récupération des trajets.';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTrips() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/trips');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _trips = data.map((t) => Trip.fromJson(t)).toList();
      } else {
        _errorMessage = 'Erreur lors de la récupération des voyages.';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Ticket?> bookTicket(int tripId, {int? seatNumber}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/tickets/book', {
        'trip_id': tripId,
        if (seatNumber != null) 'seat_number': seatNumber,
      });
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return Ticket.fromJson(data);
      } else {
        _errorMessage = data['message'] ?? 'Erreur lors de la réservation';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion.';
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<void> fetchMyTickets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.get('/tickets/my');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _myTickets = data.map((t) => Ticket.fromJson(t)).toList();
      } else {
        _errorMessage = 'Erreur lors du chargement de vos tickets.';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion.';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> scanTicket(String ticketCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/tickets/scan', {'ticket_code': ticketCode});
      final data = jsonDecode(response.body);
      
      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'ticket': Ticket.fromJson(data['ticket'])
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Code de ticket invalide'
        };
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'Erreur réseau lors de la validation.'
      };
    }
  }

  Future<bool> createLine(Map<String, dynamic> lineData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.post('/admin/lines', lineData);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _isLoading = false;
        await fetchLines();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Erreur de création';
      }
    } catch (_) {
      _errorMessage = 'Erreur réseau.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
