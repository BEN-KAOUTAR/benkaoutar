import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class PaymentViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<MonthPaymentGroup> _monthGroups = [];
  List<PaymentModel> _allPayments = []; // raw list from API
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDownloading = false;

  List<MonthPaymentGroup> get monthGroups => _monthGroups;
  List<PaymentModel> get payments => _allPayments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDownloading => _isDownloading;

  // Summary statistics (count each type separately)
  int get paidCount => _monthGroups.where((g) => g.allPaid).length;
  int get overdueCount => _monthGroups.where((g) => g.overallStatus == PaymentStatus.overdue).length;
  int get pendingCount => _monthGroups.where((g) => g.overallStatus == PaymentStatus.pending).length;
  double get progressionRate => _monthGroups.isEmpty ? 0 : (paidCount / _monthGroups.length);

  static const List<String> _schoolMonths = [
    'september', 'october', 'november', 'december',
    'january', 'february', 'march', 'april', 'may', 'june',
  ];

  static const Map<String, int> _monthToNumber = {
    'september': 9, 'october': 10, 'november': 11, 'december': 12,
    'january': 1, 'february': 2, 'march': 3, 'april': 4, 'may': 5, 'june': 6,
  };

  int _getAcademicMonthIndex(int month) {
    if (month >= 9) return month - 9;
    return month + 3;
  }

  bool _isMonthOverdue(String monthStr) {
    final now = DateTime.now();
    int currentAcademicMonth = _getAcademicMonthIndex(now.month);
    int targetMonthNum = _monthToNumber[monthStr.toLowerCase()] ?? 9;
    int targetAcademicMonth = _getAcademicMonthIndex(targetMonthNum);
    return targetAcademicMonth < currentAcademicMonth;
  }

  PaymentModel _withOverdueStatus(PaymentModel p) {
    return PaymentModel(
      id: p.id,
      month: p.month,
      amount: p.amount,
      status: PaymentStatus.overdue,
      date: p.date,
      childIds: p.childIds,
      invoiceUrl: p.invoiceUrl,
      invoiceNumber: p.invoiceNumber,
      studentName: p.studentName,
      className: p.className,
      paymentMethod: p.paymentMethod,
      year: p.year,
      paymentType: p.paymentType,
    );
  }

  Future<void> fetchPayments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apiPayments = await _apiService.getPayments();
      _allPayments = apiPayments;

      _monthGroups = _schoolMonths.map((month) {
        final bool isOverdue = _isMonthOverdue(month);
        
        // Find scolarity payment for this month
        final scoMatches = apiPayments.where((p) =>
            p.month.toLowerCase().trim() == month.toLowerCase() &&
            p.paymentType == PaymentType.scolarity).toList();
        
        // Find transport payment for this month
        final traMatches = apiPayments.where((p) =>
            p.month.toLowerCase().trim() == month.toLowerCase() &&
            p.paymentType == PaymentType.transport).toList();

        PaymentModel? sco = scoMatches.isNotEmpty ? scoMatches.first : null;
        PaymentModel? tra = traMatches.isNotEmpty ? traMatches.first : null;

        // Upgrade to overdue if unpaid and month has passed
        if (sco != null && sco.status == PaymentStatus.pending && isOverdue) {
          sco = _withOverdueStatus(sco);
        }
        if (tra != null && tra.status == PaymentStatus.pending && isOverdue) {
          tra = _withOverdueStatus(tra);
        }

        // Create overdue placeholders for months that passed with no API data
        if (sco == null && isOverdue) {
          sco = PaymentModel(
            id: 'missing_sco_$month', month: month, amount: 0,
            status: PaymentStatus.overdue, date: '', childIds: [],
            paymentType: PaymentType.scolarity,
          );
        }
        if (tra == null && isOverdue) {
          tra = PaymentModel(
            id: 'missing_tra_$month', month: month, amount: 0,
            status: PaymentStatus.overdue, date: '', childIds: [],
            paymentType: PaymentType.transport,
          );
        }

        return MonthPaymentGroup(
          month: month,
          scolarity: sco,
          transport: tra,
        );
      }).toList();
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

  Future<bool> launchURL(String urlString) async {
    if (urlString.isEmpty) return false;
    _isDownloading = true;
    notifyListeners();
    
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }
}
