import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/models/models.dart';
import '../viewmodels/payment_view_model.dart';


// ─── Main Screen ──────────────────────────────────────────────────────────────
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentViewModel>().fetchPayments();
    });
  }

  // ── Yearly Summary Card ─────────────────────────────────────────────────────
  Widget _buildYearlySummary(PaymentViewModel vm) {
    final paid = vm.paidCount;
    final total = vm.payments.length;
    final progress = vm.progressionRate;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E3A5F).withValues(alpha: 0.9),
                  const Color(0xFF0D1B2A).withValues(alpha: 0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('year_summary_range'),
                          style: TextStyle(
                            color: Colors.blueAccent.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$paid / $total ${AppLocalizations.of(context)!.translate('months_paid_count')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          Colors.blueAccent.withValues(alpha: 0.3),
                          Colors.blueAccent.withValues(alpha: 0.05),
                        ]),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.blueAccent, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    LayoutBuilder(builder: (context, constraints) {
                      return AnimatedContainer(
                        duration: 1200.ms,
                        curve: Curves.easeOutCubic,
                        height: 6,
                        width: constraints.maxWidth * progress,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF60A5FA), Color(0xFF34D399)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statPill(AppLocalizations.of(context)!.translate('paid'), '$paid', Colors.greenAccent),
                    _statPill(AppLocalizations.of(context)!.translate('overdue'), '${vm.overdueCount}', Colors.redAccent),
                    _statPill(AppLocalizations.of(context)!.translate('pending'), '${vm.pendingCount}', Colors.orangeAccent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1);
  }

  Widget _statPill(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ── Month Grid ──────────────────────────────────────────────────────────────
  Widget _buildMonthCard(PaymentModel payment, int index, bool isDark, PaymentViewModel vm) {
    // Find the first unpaid month (for "Pay Now" logic)
    bool isFirstPending = false;
    final pendingMonths = vm.payments.where((p) => p.status == PaymentStatus.pending).toList();
    if (payment.status == PaymentStatus.pending && pendingMonths.isNotEmpty && pendingMonths.first.id == payment.id) {
       isFirstPending = true;
    }

    // Colors
    Color glowColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7);
    Color borderColor = isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.9);
    Color labelColor = isDark ? Colors.white60 : Colors.black54;
    IconData? icon;

    if (payment.status == PaymentStatus.paid) {
      glowColor = isDark ? Colors.greenAccent.withValues(alpha: 0.08) : Colors.greenAccent.withValues(alpha: 0.15);
      borderColor = isDark ? Colors.greenAccent.withValues(alpha: 0.25) : Colors.greenAccent.withValues(alpha: 0.3);
      labelColor = isDark ? Colors.greenAccent : Colors.green;
      icon = Icons.check_circle_rounded;
    } else if (payment.status == PaymentStatus.overdue) {
      glowColor = isDark ? Colors.redAccent.withValues(alpha: 0.08) : Colors.redAccent.withValues(alpha: 0.1);
      borderColor = isDark ? Colors.redAccent.withValues(alpha: 0.25) : Colors.redAccent.withValues(alpha: 0.3);
      labelColor = isDark ? Colors.redAccent : Colors.red;
      icon = Icons.warning_amber_rounded;
    } else if (isFirstPending) {
      glowColor = isDark ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.blueAccent.withValues(alpha: 0.15);
      borderColor = isDark ? Colors.blueAccent.withValues(alpha: 0.4) : Colors.blueAccent.withValues(alpha: 0.3);
      labelColor = isDark ? Colors.blueAccent : Colors.blue;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (payment.status == PaymentStatus.paid) {
          _showReceiptTypeSelection(payment, vm);
        } else {
          _openPaymentWizard(payment);
        }
      },
      child: AnimatedContainer(
        duration: 300.ms,
        decoration: BoxDecoration(
          color: glowColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Stack(
          children: [
            // Glow dot top-right
            if (payment.status == PaymentStatus.paid || payment.status == PaymentStatus.overdue)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(icon, color: labelColor, size: 14),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate(payment.month).substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      color: labelColor.withValues(alpha: 0.6),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppLocalizations.of(context)!.translate(payment.month),
                    style: TextStyle(
                      color: payment.status != PaymentStatus.pending || isFirstPending
                          ? labelColor
                          : (isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.4)),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (payment.status == PaymentStatus.pending)
                    Text(
                      isFirstPending ? '${AppLocalizations.of(context)!.translate('pay_now')} →' : AppLocalizations.of(context)!.translate('pending'),
                      style: TextStyle(
                        color: isFirstPending ? (isDark ? Colors.blueAccent : Colors.blue) : (isDark ? Colors.white24 : Colors.black26),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (30 * index).ms).scale(begin: const Offset(0.93, 0.93));
  }

  // ── Receipt Bottom Sheet ────────────────────────────────────────────────────
  void _showReceiptTypeSelection(PaymentModel payment, PaymentViewModel vm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bgColor = isDark ? const Color(0xFF1E3A5F) : Colors.white;
    final bgColor2 = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF1F5F9);
    final handleColor = isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgColor, bgColor2],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.translate('receipt_type').toUpperCase(),
                style: TextStyle(
                  color: primaryTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 24),
              _buildTypeOption(
                title: AppLocalizations.of(context)!.translate('scolarity_receipt'),
                icon: Icons.school_rounded,
                color: Colors.blueAccent,
                onTap: () {
                  Navigator.pop(context);
                  _showReceiptSheet(payment, vm, isTransport: false);
                },
              ),
              const SizedBox(height: 16),
              _buildTypeOption(
                title: AppLocalizations.of(context)!.translate('transport_receipt'),
                icon: Icons.directions_bus_rounded,
                color: Colors.orangeAccent,
                onTap: () {
                  Navigator.pop(context);
                  _showReceiptSheet(payment, vm, isTransport: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeOption({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: primaryTextColor.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  void _showReceiptSheet(PaymentModel payment, PaymentViewModel vm, {bool isTransport = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.6);
    final bgColor = isDark ? const Color(0xFF1A2D47) : Colors.white;
    final bgColor2 = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF1F5F9);
    final handleColor = isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1);

    final invoiceId = '#2026-${payment.id.padLeft(2, '0')}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ListenableBuilder(
          listenable: vm,
          builder: (context, child) {
             bool isDownloading = vm.isDownloading;
             bool isDone = false; // We can manage local done state or use vm state

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bgColor, bgColor2],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: handleColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTransport ? 'REÇU DE TRANSPORT' : 'REÇU DE SCOLARITÉ',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Invoice $invoiceId',
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.translate('paid').toUpperCase(),
                                style: TextStyle(
                                  color: Colors.greenAccent.shade200,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.check_rounded, color: Colors.greenAccent.shade200, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _receiptInfoRow(AppLocalizations.of(context)!.translate('date_label'), payment.date),
                    const SizedBox(height: 14),
                    _receiptInfoRow(isTransport ? 'Service' : 'École', isTransport ? 'Transport Scolaire' : 'École Al Irfane'),
                    const SizedBox(height: 14),
                    _receiptInfoRow(AppLocalizations.of(context)!.translate('month_label'), AppLocalizations.of(context)!.translate(payment.month)),
                    const SizedBox(height: 28),
                    Container(
                      height: 1,
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'DÉTAIL',
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF0F172A).withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                     // Simplified for now: assuming 1 child or generic description
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Scolarité ${AppLocalizations.of(context)!.translate(payment.month)}",
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${payment.amount.toInt()} DH',
                            style: TextStyle(
                              color: isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF0F172A).withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL PAYÉ',
                            style: TextStyle(
                              color: isDark ? Colors.blueAccent.shade100 : Colors.blueAccent.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            '${payment.amount.toInt()} DH',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () async {
                        if (isDownloading) return;
                        HapticFeedback.mediumImpact();
                        
                        final url = await vm.getReceiptUrl(payment.id, isTransport ? 'transport' : 'scolarity');
                        
                        if (url != null) {
                           HapticFeedback.heavyImpact();
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text(AppLocalizations.of(context)!.translate('download_success')))
                             );
                             Navigator.pop(context);
                           }
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isDownloading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else
                              const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                              
                            const SizedBox(width: 10),
                            Text(
                              isDownloading 
                                ? AppLocalizations.of(context)!.translate('downloading')
                                : AppLocalizations.of(context)!.translate('download_receipt'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _receiptInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.6);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  void _openPaymentWizard(PaymentModel payment) {
    HapticFeedback.selectionClick();
    // Future: implement payment flow
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
              ),
              child: Image.asset('assets/images/image3.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 14),
            Text(
              AppLocalizations.of(context)!.translate('payments_title'),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                fontSize: 22,
                letterSpacing: -0.8,
              ),
            ),
          ],
        ),
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: Consumer<PaymentViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading && vm.payments.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
            }

            if (vm.errorMessage != null && vm.payments.isEmpty) {
               return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context)!.translate(vm.errorMessage!), style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => vm.fetchPayments(),
                      child: Text(AppLocalizations.of(context)!.translate('retry')),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  _buildYearlySummary(vm),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('monthly_payments').toUpperCase(),
                          style: TextStyle(
                            color: isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF0F172A).withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.88,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: vm.payments.length,
                      itemBuilder: (ctx, i) => _buildMonthCard(vm.payments[i], i, isDark, vm),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}