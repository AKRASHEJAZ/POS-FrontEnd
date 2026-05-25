import 'package:flutter/material.dart';
import 'package:web_end/models/user_model.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';

/// Persistent user + logout block pinned below the navigation rail.
class RailProfileTrailing extends StatelessWidget {
  final UserModel? user;
  final bool railExtended;
  final bool isLoading;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  const RailProfileTrailing({
    super.key,
    required this.user,
    required this.railExtended,
    required this.isLoading,
    required this.isLoggingOut,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: railExtended ? 256 : 80,
      padding: EdgeInsets.fromLTRB(
        railExtended ? 12 : 8,
        8,
        railExtended ? 12 : 8,
        12,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.soft.withValues(alpha: 0.35)),
        ),
      ),
      child: isLoading ? _buildLoading() : _buildContent(context),
    );
  }

  Widget _buildLoading() {
    return SizedBox(
      height: railExtended ? 88 : 72,
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.mid),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (!railExtended) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAvatar(context, radius: 18),
          const SizedBox(height: 8),
          _buildLogoutButton(compact: true),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildAvatar(context, radius: 22),
            const SizedBox(width: 10),
            Expanded(child: _buildUserLabels(context)),
          ],
        ),
        const SizedBox(height: 10),
        _buildLogoutButton(compact: false),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, {required double radius}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.mid,
      child: Text(
        user?.initials ?? '?',
        style: AppTheme.apply(
          TextStyle(
            color: AppColors.light,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.65,
          ),
        ),
      ),
    );
  }

  Widget _buildUserLabels(BuildContext context) {
    final nameStyle = AppTheme.body(context)?.copyWith(fontWeight: FontWeight.w600);
    final emailStyle = AppTheme.subtitle(context);
    final roleStyle = AppTheme.apply(
      const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.deep,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user?.name ?? 'User',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: nameStyle,
        ),
        const SizedBox(height: 2),
        Text(
          user?.email ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: emailStyle,
        ),
        if (user?.role != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.soft.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(user!.role!, style: roleStyle),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoutButton({required bool compact}) {
    if (compact) {
      return Tooltip(
        message: 'Logout',
        child: IconButton(
          onPressed: isLoggingOut ? null : onLogout,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.deep,
            backgroundColor: AppColors.soft.withValues(alpha: 0.2),
          ),
          icon: isLoggingOut
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout, size: 20),
        ),
      );
    }

    return SizedBox(
      height: 38,
      child: OutlinedButton.icon(
        onPressed: isLoggingOut ? null : onLogout,
        icon: isLoggingOut
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.logout, size: 18),
        label: Text(isLoggingOut ? 'Signing out...' : 'Logout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deep,
          side: BorderSide(color: AppColors.mid.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
