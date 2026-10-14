import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/cart_page/widgets/delivery_type_widget.dart';
import '../../../config/helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/widgets/custom_toast.dart';

/// Combined Delivery Type + Delivery Speed — one card, old visual style.
///
/// - Pickup / Delivery shown as vertical column cards (same look as before)
/// - When Delivery is selected the Rush/Regular speed options expand inline
///   using the same visual style as the old DeliveryTypeWidget (bordered cards,
///   radio buttons, "Fastest Option" badge, charge label).
class DeliveryMethodSelectorWidget extends StatelessWidget {
  final String selectedMethod;
  final bool isPickupEnabled;
  final List<String>? blockedPickupStores;
  final ValueChanged<String> onMethodChanged;

  // Speed options — only relevant when selectedMethod == 'delivery'
  final DeliveryType? selectedDeliveryType;
  final ValueChanged<DeliveryType>? onDeliveryTypeChanged;
  final double rushDeliveryCharge;
  final double regularDeliveryCharge;
  final bool isRushDeliveryDisabled;

  const DeliveryMethodSelectorWidget({
    super.key,
    required this.selectedMethod,
    this.isPickupEnabled = true,
    this.blockedPickupStores,
    required this.onMethodChanged,
    this.selectedDeliveryType,
    this.onDeliveryTypeChanged,
    this.rushDeliveryCharge = 0,
    this.regularDeliveryCharge = 0,
    this.isRushDeliveryDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final isPickup = selectedMethod == 'pickup';
    final isDelivery = selectedMethod == 'delivery';

    return Container(
      padding: EdgeInsets.only(
        left: 12.0.w,
        right: 12.0.w,
        top: 12.h,
        bottom: 12.h,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Text(
            l10n?.deliveryType ?? 'Delivery Type',
            style: TextStyle(
              fontSize: isTablet(context) ? 24 : 15.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),

          // ── Pickup card ───────────────────────────────────────
          if (AppHelpers.pickupEnabled) ...[
            _buildMethodCard(
              context: context,
              isSelected: isPickup,
              label: l10n?.pickup ?? 'Pickup',
              icon: isPickupEnabled ? Icons.storefront_outlined : Icons.lock_outline,
              isEnabled: isPickupEnabled,
              onTap: () => onMethodChanged('pickup'),
              onDisabledTap: () {
                final storesText = (blockedPickupStores != null && blockedPickupStores!.isNotEmpty)
                    ? blockedPickupStores!.join(', ')
                    : 'selected store';
                ToastManager.show(
                  context: context,
                  message: 'The following store(s) do not support Pickup: $storesText',
                  type: ToastType.error,
                );
              },
            ),
            SizedBox(height: 8.h),
          ],

          // ── Delivery card ─────────────────────────────────────
          _buildMethodCard(
            context: context,
            isSelected: isDelivery,
            label: l10n?.delivery ?? 'Delivery',
            icon: Icons.local_shipping_outlined,
            isEnabled: true,
            onTap: () => onMethodChanged('delivery'),
          ),

          // ── Inline speed options (old DeliveryTypeWidget style) ─
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSpeedSection(context, l10n),
            crossFadeState:
                isDelivery && onDeliveryTypeChanged != null ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 260),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }

  // ── Method card (same old style) ─────────────────────────────────────────
  Widget _buildMethodCard({
    required BuildContext context,
    required bool isSelected,
    required String label,
    required IconData icon,
    bool isEnabled = true,
    required VoidCallback onTap,
    VoidCallback? onDisabledTap,
  }) {
    const primaryColor = AppTheme.primaryColor;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: isEnabled ? onTap : onDisabledTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: isSelected
                ? Border.all(color: primaryColor, width: 1.5)
                : Border.all(color: Theme.of(context).colorScheme.outline),
            color: isSelected ? primaryColor.withValues(alpha: 0.08) : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  size: isTablet(context) ? 28 : 22.sp,
                  color: isSelected ? primaryColor : Colors.grey[600],
                ),
              ),
              SizedBox(width: 14.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet(context) ? 18 : 14.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primaryColor : Colors.grey[700],
                ),
              ),
              const Spacer(),
              RadioGroup<String>(
                groupValue: selectedMethod,
                onChanged: (String? value) {
                  if (!isEnabled) {
                    onDisabledTap?.call();
                    return;
                  }
                  if (value != null) {
                    onMethodChanged(value);
                  }
                },
                child: Radio<String>(
                  value: label.toLowerCase(),
                  side: const BorderSide(color: AppTheme.primaryColor),
                  activeColor: AppTheme.primaryColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Speed section — identical look to old DeliveryTypeWidget ─────────────
  Widget _buildSpeedSection(BuildContext context, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: Row(
            children: [
              Icon(
                Icons.speed_outlined,
                size: 14.sp,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 6.w),
              Text(
                l10n?.deliverySpeed ?? 'Delivery Speed',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: isTablet(context) ? 24 : 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        _buildSpeedOption(
          context: context,
          deliveryType: DeliveryType.rush,
          title: l10n?.rushDelivery ?? 'Rush Delivery',
          subtitle: l10n?.prioritizedDeliveryForYourUrgentNeeds ?? 'Prioritized delivery for your urgent needs.',
          extraCharge: rushDeliveryCharge,
          l10n: l10n,
        ),
        SizedBox(height: 8.h),
        _buildSpeedOption(
          context: context,
          deliveryType: DeliveryType.regular,
          title: l10n?.regularDelivery ?? 'Regular Delivery',
          subtitle: l10n?.standardDeliveryWithNoExtraCharges ?? 'Standard delivery with no extra charges.',
          extraCharge: regularDeliveryCharge,
          l10n: l10n,
        ),
      ],
    );
  }

  Widget _buildSpeedOption({
    required BuildContext context,
    required DeliveryType deliveryType,
    required String title,
    required String subtitle,
    double? extraCharge,
    required AppLocalizations? l10n,
  }) {
    final bool isEnabled = deliveryType == DeliveryType.regular || !isRushDeliveryDisabled;
    final bool isSelected = selectedDeliveryType == deliveryType;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: isEnabled
            ? () {
                if (deliveryType == DeliveryType.rush && isRushDeliveryDisabled) return;
                onDeliveryTypeChanged?.call(deliveryType);
              }
            : null,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: isSelected
                ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4), width: 1.0)
                : Border.all(color: Theme.of(context).colorScheme.outline),
            color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Colors.transparent,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEnabled)
                    RadioGroup<DeliveryType>(
                      groupValue: selectedDeliveryType,
                      onChanged: (DeliveryType? value) {
                        if (value != null) onDeliveryTypeChanged?.call(value);
                      },
                      child: Radio<DeliveryType>(
                        value: deliveryType,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        activeColor: AppTheme.primaryColor,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  else
                    Radio<DeliveryType>(
                      value: deliveryType,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: isTablet(context) ? 18 : 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (deliveryType == DeliveryType.rush)
                                  const Icon(
                                    Icons.bolt,
                                    color: Colors.orange,
                                    size: 20,
                                  )
                              ],
                            ),
                            if (extraCharge != null && extraCharge > 0)
                              Text(
                                '+${AppHelpers.currency}${extraCharge.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: isTablet(context) ? 14 : 10.sp,
                            color: Colors.grey[600],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
