import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_state.dart';
import 'package:hyper_local/screens/home_page/model/featured_section_product_model.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';

class HomeFeaturedSection extends StatelessWidget {
  final Widget middleBanner;
  final Widget Function(FeaturedSectionData section) buildFeatureSection;
  final Widget loadingPlaceholder;

  const HomeFeaturedSection({
    super.key,
    required this.middleBanner,
    required this.buildFeatureSection,
    required this.loadingPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeatureSectionProductBloc, FeatureSectionProductState>(
      builder: (context, state) {
        if (state is FeatureSectionProductLoaded) {
          final validSections = state.featureSectionProductData
              .where((section) => section.products.isNotEmpty)
              .toList();

          final List<Widget> sectionWidgets = [];
          if (validSections.isNotEmpty) {
            sectionWidgets.add(buildFeatureSection(validSections.first));
            sectionWidgets.add(middleBanner);

            if (validSections.length > 1) {
              sectionWidgets.addAll(
                validSections.skip(1).map(buildFeatureSection),
              );
            }
          } else {
            sectionWidgets.add(middleBanner);
          }

          return ListView(
            padding: EdgeInsets.only(top: 5.h),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ...sectionWidgets,
              if (!state.hasReachedMax)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CustomCircularProgressIndicator(),
                  ),
                ),
            ],
          );
        }

        if (state is FeatureSectionProductLoading) {
          return loadingPlaceholder;
        }

        return Column(
          children: [
            middleBanner,
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}
