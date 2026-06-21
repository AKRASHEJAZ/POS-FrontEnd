import 'package:flutter/material.dart';
import 'package:web_end/models/count_data_model.dart';
import 'package:web_end/services/report/report_service.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';
import 'package:web_end/widgets/common/responsive_page_padding.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _service = ReportService();

  CountDataModel? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _service.getCountData();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _data = result.data;
      } else {
        _error = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: responsivePagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard', style: AppTheme.title(context)),
                      const SizedBox(height: 4),
                      Text(
                        'Quick overview of your business',
                        style: AppTheme.subtitle(context),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh, color: AppColors.mid),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Body ────────────────────────────────────────────────
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 64),
                  child: CircularProgressIndicator(color: AppColors.mid),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: Column(
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red.shade400),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: TextStyle(color: Colors.red.shade600)),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_data != null)
              _buildCards(_data!),
          ],
        ),
      ),
    );
  }

  // ── Card grid ───────────────────────────────────────────────────────────────

  Widget _buildCards(CountDataModel d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Products
        _sectionLabel('Products'),
        const SizedBox(height: 12),
        _cardRow([
          _StatCard(
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.mid,
            label: 'Total Products',
            value: d.totalProducts.toString(),
          ),
          _StatCard(
            icon: Icons.check_circle_outline,
            iconColor: Colors.green.shade600,
            label: 'Active',
            value: d.activeProducts.toString(),
          ),
          _StatCard(
            icon: Icons.cancel_outlined,
            iconColor: Colors.red.shade400,
            label: 'Inactive',
            value: (d.totalProducts - d.activeProducts).toString(),
          ),
        ]),
        const SizedBox(height: 28),

        // Users
        _sectionLabel('Users'),
        const SizedBox(height: 12),
        _cardRow([
          _StatCard(
            icon: Icons.people_outline,
            iconColor: AppColors.mid,
            label: 'Total Users',
            value: d.totalUsers.toString(),
          ),
          _StatCard(
            icon: Icons.person_outline,
            iconColor: Colors.green.shade600,
            label: 'Active',
            value: d.activeUsers.toString(),
          ),
        ]),
        const SizedBox(height: 28),

        // Financials
        _sectionLabel('Financials'),
        const SizedBox(height: 12),
        _cardRow([
          _StatCard(
            icon: Icons.point_of_sale_outlined,
            iconColor: Colors.green.shade700,
            label: 'Total Sales',
            value: _fmt(d.totalSale),
            prefix: 'Rs.',
          ),
          _StatCard(
            icon: Icons.report_problem_outlined,
            iconColor: Colors.orange.shade700,
            label: 'Total Damages',
            value: _fmt(d.totalDamages),
            prefix: 'Rs.',
          ),
          _StatCard(
            icon: Icons.assignment_return_outlined,
            iconColor: Colors.blue.shade600,
            label: 'Total Returns',
            value: _fmt(d.totalReturns),
            prefix: 'Rs.',
          ),
        ]),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTheme.label(context)?.copyWith(
        fontSize: 13,
        letterSpacing: 0.4,
        color: AppColors.deep.withValues(alpha: 0.55),
      ),
    );
  }

  Widget _cardRow(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        if (compact) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: c,
                    ))
                .toList(),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? prefix;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.soft.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style:
                        AppTheme.subtitle(context)?.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style:
                          AppTheme.title(context)?.copyWith(fontSize: 22),
                      children: [
                        if (prefix != null)
                          TextSpan(
                            text: '$prefix ',
                            style: AppTheme.subtitle(context)
                                ?.copyWith(fontSize: 13),
                          ),
                        TextSpan(text: value),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
