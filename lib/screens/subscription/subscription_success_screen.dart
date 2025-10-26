import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/subscription_plan.dart';
import '../../services/session_service.dart';
import '../../services/payment_service.dart';
import '../../utils/constants/subscription_constants.dart';

class SubscriptionSuccessScreen extends StatefulWidget {
  final SubscriptionPlan plan;

  const SubscriptionSuccessScreen({super.key, required this.plan});

  @override
  State<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState extends State<SubscriptionSuccessScreen> {
  dynamic currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final userType = await SessionService.getCurrentUserType();
    if (userType == 'Employer') {
      currentUser = await SessionService.getCurrentEmployer();
    } else if (userType == 'Helper') {
      currentUser = await SessionService.getCurrentHelper();
    }
    setState(() => isLoading = false);
  }

  Future<void> _launchPayMongo() async {
    final plan = widget.plan;
    final userId = currentUser?.id;

    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final paymentLink = await PaymentService.createPaymentLink(
      amount: plan.price.toDouble(),
      userId: userId,
      planName: plan.name,
    );

    if (paymentLink != null && await canLaunchUrl(Uri.parse(paymentLink))) {
      await launchUrl(
        Uri.parse(paymentLink),
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open PayMongo link'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    final planColor = Color(
      SubscriptionConstants.planColors[plan.id] ?? 0xFF2196F3,
    );

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Checkout Subscription'),
        backgroundColor: planColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: planColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Plan Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: planColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      SubscriptionConstants.planIcons[plan.id] ?? '💳',
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: planColor,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  '₱${plan.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Steps to follow:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: planColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Tap the button below to open the PayMongo payment page.\n'
                  '2. Complete the payment using GCash, GrabPay, or your card.\n'
                  '3. Once successful, your subscription will be automatically activated.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _launchPayMongo,
                    icon: const Icon(Icons.payment),
                    label: const Text(
                      'Pay via PayMongo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: planColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
