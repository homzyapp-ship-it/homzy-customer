import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import '../../../config/helper.dart';

class ReferralBanner extends StatefulWidget {
  final VoidCallback onYes;
  final VoidCallback onNo;

  const ReferralBanner({
    super.key,
    required this.onYes,
    required this.onNo,
  });

  @override
  State<ReferralBanner> createState() => _ReferralBannerState();
}

class _ReferralBannerState extends State<ReferralBanner> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _progressController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onNo();
      }
    });

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
          decoration: BoxDecoration(
            color: isDarkMode(context) ? Colors.black : Colors.white, // Dark background matching Image 2 & 3!
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: isDarkMode(context) ? Colors.white : Colors.black,
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.haveReferralCodeTitle,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode(context) ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            l10n.haveReferralCodeSubtitle,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 10.sp,
                              color: isDarkMode(context) ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: widget.onNo,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Text(
                              l10n.no,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode(context) ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: widget.onYes,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: EdgeInsets.all(4.w),
                            child: Text(
                              l10n.yes,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor, // Blue button text matching Image 2 & 3
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Progress bar countdown
              SizedBox(
                height: 1.5.h,
                width: double.infinity,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 1.0 - _progressController.value,
                    child: Container(
                      color: AppTheme.primaryColor, // Match progress color to the blue action button!
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
  }
}
