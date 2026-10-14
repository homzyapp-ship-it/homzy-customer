import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart' show ProductData;
import 'package:hyper_local/utils/widgets/custom_see_all_button.dart';

import '../../../../config/helper.dart';
import '../../section_gallery/data/section_background.dart';
import 'home_layout_product_card.dart';

class DynamicProductSection extends StatelessWidget {
  final String title;
  final List<ProductData> products;
  final String orientation;
  final SectionBackground background;
  final String backgroundImageStyle;
  final VoidCallback? onSeeAll;
  final EdgeInsets? outerPadding;
  final double? horizontalGap;
  final double? verticalGap;
  final Color? textColor;
  final BorderRadius? borderRadius;

  const DynamicProductSection({
    super.key,
    required this.title,
    required this.products,
    this.orientation = 'horizontal',
    this.background = const SectionBackground.none(),
    this.backgroundImageStyle = 'full',
    this.onSeeAll,
    this.outerPadding,
    this.horizontalGap,
    this.verticalGap,
    this.textColor,
    this.borderRadius,
  });

  bool get _isGrid => orientation == 'vertical';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool isHalfBg = background.type == SectionBackgroundType.image && backgroundImageStyle == 'half';

    final effectiveBackground = isHalfBg
        ? const SectionBackground.none()
        : ((_isGrid && background.type == SectionBackgroundType.image && backgroundImageStyle == 'full')
            ? const SectionBackground.none()
            : background);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 10.w, 16.w, 14.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _body(context),
        if (onSeeAll != null)
          Center(
            child: CustomSeeAllButton(
              onTap: onSeeAll!,
            ),
          ),
      ],
    );

    if (isHalfBg) {
      return Container(
        decoration: borderRadius != null ? BoxDecoration(borderRadius: borderRadius) : null,
        margin: outerPadding,
        clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 180.h,
              child: Container(
                decoration: background.toDecoration(),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 90.h),
              child: content,
            ),
          ],
        ),
      );
    }

    final dec = effectiveBackground.toDecoration();
    final decoration = dec is BoxDecoration
        ? dec.copyWith(borderRadius: borderRadius)
        : (borderRadius != null ? BoxDecoration(borderRadius: borderRadius) : null);

    return Container(
      decoration: decoration,
      margin: outerPadding,
      clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
      padding: effectiveBackground.hasBackground ? EdgeInsets.symmetric(vertical: 16.h) : EdgeInsets.zero,
      child: content,
    );
  }

  Widget _body(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    if (_isGrid) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: (horizontalGap ?? 10.0).w,
            mainAxisSpacing: (verticalGap ?? 10.0).h,
            mainAxisExtent: 240.h,
          ),
          padding: EdgeInsets.zero,
          itemBuilder: (context, i) => HomeLayoutProductCard(data: products[i]),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: products.map((product) {
            return SizedBox(
              width: isTablet(context) ? 180.w : 120.w,
              child: Padding(
                padding: EdgeInsets.only(right: (horizontalGap ?? 12.0).w),
                child: HomeLayoutProductCard(data: product),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
