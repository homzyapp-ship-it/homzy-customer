import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/banner/banner_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/banner/banner_state.dart';
import 'package:hyper_local/screens/home_page/bloc/brands/brands_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_state.dart';
import 'package:hyper_local/screens/home_page/bloc/sub_category/sub_category_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/sub_category/sub_category_state.dart';
import 'package:hyper_local/screens/home_page/model/featured_section_product_model.dart';
import 'package:hyper_local/screens/home_page/widgets/banner_slider.dart';
import 'package:hyper_local/screens/home_page/widgets/brands_widget.dart';
import 'package:hyper_local/screens/home_page/widgets/sub_category_feature_section_widget.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';

import 'home_featured_section.dart';

class HomeTabContentSection extends StatelessWidget {
  final String brandsSectionTitle;
  final String categorySlug;
  final Widget middleBanner;
  final Widget loadingPlaceholder;
  final Widget Function(FeaturedSectionData section) buildFeatureSection;
  final VoidCallback onRetry;

  const HomeTabContentSection({
    super.key,
    required this.brandsSectionTitle,
    required this.categorySlug,
    required this.middleBanner,
    required this.loadingPlaceholder,
    required this.buildFeatureSection,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BannerBloc, BannerState>(
      builder: (context, bannerState) {
        return BlocBuilder<SubCategoryBloc, SubCategoryState>(
          builder: (context, subCategoryState) {
            return BlocBuilder<FeatureSectionProductBloc,
                FeatureSectionProductState>(
              builder: (context, featureSectionState) {
                return BlocBuilder<BrandsBloc, BrandsState>(
                  builder: (context, brandsState) {
                    final hasFailed = bannerState is BannerFailed &&
                        subCategoryState is SubCategoryFailed &&
                        featureSectionState is FeatureSectionProductFailed &&
                        brandsState is BrandsFailed;
                    if (hasFailed) {
                      return NoDeliveryLocationPage(onRetry: onRetry);
                    }
                    return CustomScrollView(
                      clipBehavior: Clip.antiAlias,
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildTopBanner(bannerState),
                        ),
                        const SliverToBoxAdapter(
                          child: SubCategoryFeatureSectionWidget(),
                        ),
                        SliverToBoxAdapter(
                          child: BrandsSection(
                            brandsSectionTitle: brandsSectionTitle,
                            categorySlug: categorySlug,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: HomeFeaturedSection(
                            middleBanner: middleBanner,
                            buildFeatureSection: buildFeatureSection,
                            loadingPlaceholder: loadingPlaceholder,
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 70),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTopBanner(BannerState state) {
    if (state is BannerLoaded) {
      return AutoPlayCarouselSlider(banners: state.topBannerData);
    }

    if (state is BannerLoading) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: ShimmerWidget.rectangular(
          isBorder: true,
          height: 220,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
