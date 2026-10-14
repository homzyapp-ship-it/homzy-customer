import 'package:flutter/material.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/l10n/app_localizations.dart';

class CustomSeeAllButton extends StatelessWidget {
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const CustomSeeAllButton({
    super.key,
    required this.onTap,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 5, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFEAECF2),
          ),
          borderRadius: BorderRadius.circular(6),
          color: isDarkMode(context) ? null : const Color(0xFFF3F5F7),
        ),
        padding: padding ?? const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.seeAll,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isTablet(context) ? 18 : 14,
              ),
            ),
            const Icon(Icons.arrow_right_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}
