import 'package:flutter/material.dart';
import 'package:web_end/models/user_model.dart';
import 'package:web_end/theme/app_theme.dart';
import 'package:web_end/theme/themeColor.dart';

/// Full profile block for the mobile drawer.
class ProfileSection extends StatelessWidget {
  final UserModel? user;
  final bool isLoading;
  final bool isLoggingOut;
  final VoidCallback onLogout;

  const ProfileSection({
    super.key,
    required this.user,
    required this.isLoading,
    required this.isLoggingOut,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.mid,
            ),
          ),
        ),
      );
    }

    final nameStyle = AppTheme.body(context)?.copyWith(fontWeight: FontWeight.w600);
    final emailStyle = AppTheme.subtitle(context);
    final roleStyle = AppTheme.apply(
      const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.deep,
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.mid,
                child: Text(
                  user?.initials ?? '?',
                  style: AppTheme.apply(
                    const TextStyle(
                      color: AppColors.light,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.soft.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(user!.role!, style: roleStyle),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
