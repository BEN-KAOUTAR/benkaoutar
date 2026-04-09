import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class PaymentViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDownloading = false;

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDownloading => _isDownloading;

  // Summary statistics
  int get paidCount => _payments.where((p) => p.status == PaymentStatus.paid).length;
  int get overdueCount => _payments.where((p) => p.status == PaymentStatus.overdue).length;
  int get pendingCount => _payments.where((p) => p.status == PaymentStatus.pending).length;
  double get progressionRate => _payments.isEmpty ? 0 : (paidCount / _payments.length);

  Future<void> fetchPayments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _payments = await _apiService.getPayments();
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getReceiptUrl(String paymentId, String type) async {
    _isDownloading = true;
    notifyListeners();

    try {
      final url = await _apiService.downloadReceipt(paymentId, type);
      return url;
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      return null;
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }
}
