import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartstock/core/routes/app_routes.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/theme/text_styles.dart';
import 'package:smartstock/core/widgets/glass_card.dart';
import 'package:smartstock/features/integrations/screens/sync_dashboard_screen.dart';
import 'package:smartstock/features/settings/providers/settings_provider.dart';
import 'package:smartstock/features/settings/services/data_export_service.dart';
import 'package:smartstock/features/settings/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<SettingsProvider>().loadSettings();
      if (!mounted) return;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<SettingsProvider>().loadSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: SafeArea(
        child: settings.isLoading
            ? _buildLoading(isDark)
            : RefreshIndicator(
                onRefresh: () => context.read<SettingsProvider>().loadSettings(),
                child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceLight.withAlpha(100) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.settings_rounded, color: isDark ? AppColors.textSecondary : AppColors.iconPrimaryAction, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Settings', style: AppTextStyles.headlineMd.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text('Manage your shop preferences', style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                _buildProfileCard(settings, isDark),
                const SizedBox(height: 16),
                _buildShopSection(settings, isDark),
                const SizedBox(height: 16),
                _buildInventorySection(settings, isDark),
                const SizedBox(height: 16),
                _buildGoogleSheetsSection(settings, isDark),
                const SizedBox(height: 16),

                _buildDataSection(isDark),
                const SizedBox(height: 16),
                _buildVerifyAccountSection(settings, isDark),
                const SizedBox(height: 16),
                _buildAboutSection(isDark),
                const SizedBox(height: 16),
                _buildEraseDataSection(settings, isDark),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildProfileCard(SettingsProvider settings, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                (settings.storeName.isNotEmpty ? settings.storeName[0] : 'S').toUpperCase(),
                style: const TextStyle(
                    fontFamily: 'Hanken Grotesk', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(settings.storeName, style: AppTextStyles.titleMd.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
                if (settings.storeAddress.isNotEmpty)
                  Text(settings.storeAddress, style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopSection(SettingsProvider settings, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Shop Information', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
          const SizedBox(height: 12),
          _settingRow(icon: Icons.store_rounded, label: 'Store Name', value: settings.storeName, isDark: isDark, onTap: () => _showEditStoreNameDialog(settings)),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.attach_money_rounded, label: 'Currency', value: '${settings.currency} (${settings.currencySymbol})', isDark: isDark, onTap: () => _showCurrencySelector(settings)),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.access_time_rounded, label: 'Timezone', value: settings.timezone, isDark: isDark, onTap: () => _showTimezoneSelector(settings)),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.email_rounded, label: 'Store Email', value: settings.storeEmail.isEmpty ? 'Not set' : settings.storeEmail, isDark: isDark, onTap: () => _showEditFieldDialog(settings, 'Store Email', settings.storeEmail, (v) => settings.updateStoreEmail(v))),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.phone_rounded, label: 'Store Phone', value: settings.storePhone.isEmpty ? 'Not set' : settings.storePhone, isDark: isDark, onTap: () => _showEditFieldDialog(settings, 'Store Phone', settings.storePhone, (v) => settings.updateStorePhone(v))),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.location_on_rounded, label: 'Store Address', value: settings.storeAddress.isEmpty ? 'Not set' : settings.storeAddress, isDark: isDark, onTap: () => _showEditFieldDialog(settings, 'Store Address', settings.storeAddress, (v) => settings.updateStoreAddress(v))),
        ],
      ),
    );
  }

  Widget _buildInventorySection(SettingsProvider settings, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inventory Settings', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
          const SizedBox(height: 12),
          _settingRow(icon: Icons.inventory_2_rounded, label: 'Low Stock Threshold', value: '≤ ${settings.lowStockThreshold} units', isDark: isDark, onTap: () => _showThresholdDialog(settings, 'low')),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.inventory_rounded, label: 'Overstock Threshold', value: '≥ ${settings.overstockThreshold} units', isDark: isDark, onTap: () => _showThresholdDialog(settings, 'over')),
        ],
      ),
    );
  }

  Widget _buildGoogleSheetsSection(SettingsProvider settings, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncDashboardScreen())),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.table_chart_rounded, size: 20, color: AppColors.primary)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Google Sheets Backup', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text('Configure and sync data to Google Sheets',
                      style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
                ],
              ),
            ),
            Container(width: 26, height: 26,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF1F5F9)).withAlpha(150),
                borderRadius: BorderRadius.circular(8),
              ),
                child: Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.textMuted : AppColors.iconCardAction),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection(bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Data', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
          const SizedBox(height: 12),
          _settingRow(icon: Icons.download_rounded, label: 'Download Data', value: 'Save all data as CSV file', isDark: isDark, onTap: () => _exportData()),
          Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
          _settingRow(icon: Icons.category_rounded, label: 'Manage Categories', value: 'View, add, and edit categories', isDark: isDark, onTap: () => Navigator.pushNamed(context, AppRoutes.categories)),
        ],
      ),
    );
  }

  Widget _buildVerifyAccountSection(SettingsProvider settings, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Account Verification', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: settings.isEmailVerified ? AppColors.success.withAlpha(25) : AppColors.warning.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  settings.isEmailVerified ? 'Verified' : 'Unverified',
                  style: AppTextStyles.caption.copyWith(
                    color: settings.isEmailVerified ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (settings.isEmailVerified) ...[
            _settingRow(
              icon: Icons.email_rounded,
              label: 'Verified Email',
              value: settings.verifiedEmail,
              isDark: isDark,
            ),
            Divider(height: 1, color: isDark ? AppColors.greyDarker.withAlpha(60) : const Color(0xFFE2E8F0)),
            _settingRow(
              icon: Icons.swap_horiz_rounded,
              label: 'Change Email',
              value: 'Verify a different email address',
              isDark: isDark,
              onTap: () => _showChangeEmailDialog(settings),
            ),
          ] else ...[
            _settingRow(
              icon: Icons.verified_user_rounded,
              label: 'Verify Email',
              value: 'Add and verify your email address',
              isDark: isDark,
              onTap: () => _showVerifyEmailDialog(settings),
            ),
          ],
        ],
      ),
    );
  }

  void _showVerifyEmailDialog(SettingsProvider settings) {
    final emailController = TextEditingController();
    final otpController = TextEditingController();
    bool sending = false;
    bool otpSent = false;
    String? pendingEmail;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(otpSent ? 'Enter OTP' : 'Verify Email',
                  style: AppTextStyles.titleMd.copyWith(color: _getTextColor(context))),
              const SizedBox(height: 4),
              Text(otpSent
                  ? 'A 6-digit OTP has been sent to $pendingEmail'
                  : 'Enter your email to receive an OTP',
                  style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
              if (!otpSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: _getTextColor(context)),
                ),
              ] else ...[
                const SizedBox(height: 12),
                TextField(
                  controller: otpController,
                  decoration: const InputDecoration(labelText: 'Enter OTP'),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(color: _getTextColor(context)),
                ),
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: sending
                        ? null
                        : () async {
                            if (!otpSent) {
                              final email = emailController.text.trim();
                              if (email.isEmpty) return;
                              setDialogState(() => sending = true);
                              try {
                                await settings.sendOtp(email);
                                setDialogState(() {
                                  sending = false;
                                  otpSent = true;
                                  pendingEmail = email;
                                });
                              } catch (e) {
                                setDialogState(() => sending = false);
                                _showSnackBar('Error: ${e.toString()}');
                              }
                            } else {
                              final otp = otpController.text.trim();
                              if (otp.length != 6) return;
                              setDialogState(() => sending = true);
                              final verified = await settings.verifyOtp(pendingEmail!, otp);
                              setDialogState(() => sending = false);
                              if (verified) {
                                Navigator.pop(ctx);
                                _showSnackBar('Email verified successfully!');
                              } else {
                                _showSnackBar('Invalid or expired OTP. Try again.');
                              }
                            }
                          },
                    child: sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(otpSent ? 'Verify OTP' : 'Send OTP'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  void _showChangeEmailDialog(SettingsProvider settings) {
    final otpController = TextEditingController();
    final newEmailController = TextEditingController();
    final newOtpController = TextEditingController();
    bool sending = false;
    bool otpSent = false;
    int step = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (!otpSent) {
            setDialogState(() => otpSent = true);
            settings.sendChangeOtp(settings.verifiedEmail);
          }
          return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Change Email', style: AppTextStyles.titleMd.copyWith(color: _getTextColor(context))),
              const SizedBox(height: 4),
              Text(
                step == 0
                    ? 'Step 1: OTP sent to ${settings.verifiedEmail}'
                    : step == 1
                        ? 'Step 2: Enter your new email'
                        : 'Step 3: OTP sent to ${newEmailController.text.isNotEmpty ? newEmailController.text : "new email"}',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
              ),
              if (step == 0) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: otpController,
                  decoration: const InputDecoration(labelText: 'Current Email OTP'),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(color: _getTextColor(context)),
                ),
              ] else if (step == 1) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: newEmailController,
                  decoration: const InputDecoration(labelText: 'New Email'),
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: _getTextColor(context)),
                ),
              ] else ...[
                const SizedBox(height: 12),
                TextField(
                  controller: newOtpController,
                  decoration: const InputDecoration(labelText: 'New Email OTP'),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: TextStyle(color: _getTextColor(context)),
                ),
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: sending
                        ? null
                        : () async {
                            if (step == 0) {
                              final otp = otpController.text.trim();
                              if (otp.length != 6) return;
                              setDialogState(() => sending = true);
                              final verified = await settings.verifyChangeOtp(settings.verifiedEmail, otp);
                              setDialogState(() => sending = false);
                              if (verified) {
                                setDialogState(() => step = 1);
                              } else {
                                _showSnackBar('Invalid OTP. Try again.');
                              }
                            } else if (step == 1) {
                              final newEmail = newEmailController.text.trim();
                              if (newEmail.isEmpty) return;
                              setDialogState(() => sending = true);
                              await settings.sendOtp(newEmail);
                              setDialogState(() {
                                sending = false;
                                step = 2;
                              });
                            } else {
                              final otp = newOtpController.text.trim();
                              if (otp.length != 6) return;
                              setDialogState(() => sending = true);
                              final verified = await settings.verifyNewEmail(newEmailController.text.trim(), otp);
                              setDialogState(() => sending = false);
                              if (verified) {
                                Navigator.pop(ctx);
                                _showSnackBar('Email changed successfully!');
                              } else {
                                _showSnackBar('Invalid OTP. Try again.');
                              }
                            }
                          },
                    child: sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(step == 0 ? 'Verify OTP' : step == 1 ? 'Send OTP' : 'Verify & Change'),
                  ),
                ),
              ]),
            ]),
          ),
        );
      },
      ),
    );
  }

  Widget _buildEraseDataSection(SettingsProvider settings, bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.error),
              const SizedBox(width: 8),
              Text('Danger Zone', style: AppTextStyles.titleSm.copyWith(color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 12),
          _settingRow(
            icon: Icons.delete_forever_rounded,
            label: 'Erase All Data',
            value: 'Permanently delete all data',
            isDark: isDark,
            onTap: () => _showEraseDataDialog(settings),
          ),
        ],
      ),
    );
  }

  void _showEraseDataDialog(SettingsProvider settings) {
    if (!settings.isEmailVerified) {
      _showSnackBar('Please verify your email first');
      return;
    }

    int countdown = 10;
    bool countdownStarted = false;
    bool otpSent = false;
    bool sending = false;
    bool erasing = false;
    final otpController = TextEditingController();
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (!countdownStarted) {
            countdownStarted = true;
            timer = Timer.periodic(const Duration(seconds: 1), (t) {
              setDialogState(() {
                countdown--;
              });
              if (countdown <= 0) {
                t.cancel();
              }
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              const SizedBox(width: 8),
              Text('Erase All Data', style: TextStyle(color: _getTextColor(context))),
            ]),
            content: otpSent
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('OTP sent to ${settings.verifiedEmail}', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: otpController,
                      decoration: const InputDecoration(labelText: 'Enter OTP'),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: TextStyle(color: _getTextColor(context)),
                    ),
                  ])
                : Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('All data will be permanently deleted. This action cannot be undone.', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    Text('Wait $countdown seconds', style: AppTextStyles.titleLg.copyWith(color: AppColors.error, fontWeight: FontWeight.w700)),
                    if (countdown > 0) const SizedBox(height: 8),
                    if (countdown > 0)
                      LinearProgressIndicator(value: countdown / 10, backgroundColor: AppColors.error.withAlpha(30), color: AppColors.error),
                  ]),
            actions: [
              TextButton(
                onPressed: () {
                  timer?.cancel();
                  Navigator.pop(ctx);
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: countdown > 0 || sending || erasing
                    ? null
                    : () async {
                        if (!otpSent) {
                          setDialogState(() => sending = true);
                          await settings.sendOtp(settings.verifiedEmail);
                          setDialogState(() {
                            sending = false;
                            otpSent = true;
                          });
                        } else {
                          final otp = otpController.text.trim();
                          if (otp.length != 6) return;
                          setDialogState(() => sending = true);
                          final verified = await settings.verifyOtp(settings.verifiedEmail, otp);
                          setDialogState(() => sending = false);
                          if (!verified) {
                            _showSnackBar('Invalid OTP');
                            return;
                          }
                          Navigator.pop(ctx);
                          timer?.cancel();
                          _showFinalConfirmDialog(settings);
                        }
                      },
                child: sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(otpSent ? 'Verify & Delete' : 'Continue'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFinalConfirmDialog(SettingsProvider settings) {
    bool sending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text('Final Warning', style: TextStyle(color: _getTextColor(context))),
          ]),
          content: Text('Are you absolutely sure? This will permanently delete all products, sales, customers, and all other data. This cannot be undone.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: sending
                  ? null
                  : () async {
                      setDialogState(() => sending = true);
                      try {
                        await settings.eraseAllData();
                        Navigator.pop(ctx);
                        _showSnackBar('All data has been erased successfully');
                      } catch (e) {
                        setDialogState(() => sending = false);
                        _showSnackBar('Error: ${e.toString()}');
                      }
                    },
              child: sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Yes, Delete Everything'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(bool isDark) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: AppTextStyles.titleSm.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
          const SizedBox(height: 12),
          _settingRow(icon: Icons.info_outline_rounded, label: 'Version', value: '1.0.0', isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildLoading(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40, height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text('Loading settings...',
                  style: AppTextStyles.bodySm.copyWith(color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingRow({required IconData icon, required String label, required String value, required bool isDark, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.surfaceLight : const Color(0xFFF3F4F6)).withAlpha(200),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: isDark ? AppColors.textSecondary : AppColors.iconCardAction)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textPrimary : AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(value, style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMuted : AppColors.textSecondary)),
                ],
              ),
            ),
            if (onTap != null)
              Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.surfaceLight : const Color(0xFFF1F5F9)).withAlpha(150),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.chevron_right_rounded, size: 16, color: isDark ? AppColors.textMuted : AppColors.iconCardAction),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditStoreNameDialog(SettingsProvider settings) {
    final controller = TextEditingController(text: settings.storeName);
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Store Name', style: AppTextStyles.titleMd.copyWith(color: _getTextColor(context))),
          const SizedBox(height: 16),
          TextField(controller: controller, decoration: const InputDecoration(labelText: 'Store Name'), style: TextStyle(color: _getTextColor(context))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () { settings.updateStoreName(controller.text.trim()); _showSnackBar('Store name updated'); Navigator.pop(ctx); }, child: const Text('Save'))),
          ]),
        ]),
      ),
    ));
  }

  void _showEditFieldDialog(SettingsProvider settings, String label, String currentValue, Future<void> Function(String) onSave) {
    final controller = TextEditingController(text: currentValue);
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.titleMd.copyWith(color: _getTextColor(context))),
          const SizedBox(height: 16),
          TextField(controller: controller, decoration: InputDecoration(labelText: label), maxLines: label == 'Store Address' ? 3 : 1, style: TextStyle(color: _getTextColor(context))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () { onSave(controller.text.trim()); _showSnackBar('$label updated'); Navigator.pop(ctx); }, child: const Text('Save'))),
          ]),
        ]),
      ),
    ));
  }

  void _showCurrencySelector(SettingsProvider settings) {
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Select Currency', style: AppTextStyles.titleMd.copyWith(color: _getTextColor(context))),
          const SizedBox(height: 12),
          ...SettingsService.currencies.map((code) {
            final symbol = SettingsService.currencySymbol(code);
            final selected = code == settings.currency;
            return InkWell(
              onTap: () { settings.updateCurrency(code); _showSnackBar('Currency set to $code ($symbol)'); Navigator.pop(ctx); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withAlpha(12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Text('$code ($symbol)', style: AppTextStyles.bodyMd.copyWith(color: _getTextColor(context), fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                  const Spacer(),
                  if (selected) Container(width: 20, height: 20,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(5)),
                    child: const Icon(Icons.check_rounded, size: 14, color: Colors.black)),
                ]),
              ),
            );
          }),
        ]),
      ),
    ));
  }

  void _showTimezoneSelector(SettingsProvider settings) {
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Select Timezone', style: AppTextStyles.titleMd.copyWith(color: _getTextColor(context))),
          const SizedBox(height: 12),
          Flexible(child: ListView(
            shrinkWrap: true,
            children: SettingsService.timezones.map((tz) {
              final selected = tz == settings.timezone;
              return InkWell(
                onTap: () { settings.updateTimezone(tz); _showSnackBar('Timezone set to $tz'); Navigator.pop(ctx); },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(color: selected ? AppColors.primary.withAlpha(12) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                  child: Row(children: [
                    Expanded(child: Text(tz, style: AppTextStyles.bodySm.copyWith(color: _getTextColor(context), fontWeight: selected ? FontWeight.w600 : FontWeight.w400))),
                    if (selected) Container(width: 20, height: 20,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(5)),
                      child: const Icon(Icons.check_rounded, size: 14, color: Colors.black)),
                  ]),
                ),
              );
            }).toList(),
          )),
        ]),
      ),
    ));
  }

  void _showThresholdDialog(SettingsProvider settings, String type) {
    final isLow = type == 'low';
    final current = isLow ? settings.lowStockThreshold : settings.overstockThreshold;
    final controller = TextEditingController(text: current.toString());
    final formKey = GlobalKey<FormState>();
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isLow ? 'Low Stock Threshold' : 'Overstock Threshold', style: AppTextStyles.titleMd.copyWith(color: _getTextColor(context))),
          const SizedBox(height: 16),
          Form(key: formKey, child: TextFormField(
            controller: controller, keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: isLow ? 'Low stock count' : 'Overstock count'),
            validator: (v) { final n = int.tryParse(v ?? ''); if (n == null || n < 0) return 'Enter a valid number'; return null; },
            style: TextStyle(color: _getTextColor(context)),
          )),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              final value = int.tryParse(controller.text) ?? current;
              if (isLow) { settings.updateLowStockThreshold(value); } else { settings.updateOverstockThreshold(value); }
              _showSnackBar('${isLow ? "Low stock" : "Overstock"} threshold updated to $value');
              Navigator.pop(ctx);
            }, child: const Text('Save'))),
          ]),
        ]),
      ),
    ));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _exportData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          margin: EdgeInsets.all(80),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Exporting data...'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      final result = await DataExportService().exportAllData();
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 10),
                Text('Export Complete'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${result.fileCount} CSV files exported'),
                Text('${result.totalRows} records total'),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.directoryPath,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                if (result.errors.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text('Errors: ${result.errors.length}',
                      style: TextStyle(color: Colors.orange)),
                ],
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Export failed: $e');
      }
    }
  }

  Color _getTextColor(BuildContext context) {
    return AppColors.textPrimary;
  }
}
