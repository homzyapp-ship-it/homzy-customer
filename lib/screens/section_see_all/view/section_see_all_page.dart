import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/dependency_injection_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../router/app_routes.dart';
import '../../home_page/model/brands_model.dart';
import '../../home_page/model/category_model.dart';
import '../../home_page/section_gallery/data/sample_section_data.dart';
import '../../home_page/section_gallery/widgets/brands/brand_style_two.dart';
import '../../home_page/section_gallery/widgets/categories/styles/category_cards_grid.dart';
import '../../product_listing_page/model/product_listing_type.dart';
import '../bloc/section_see_all_bloc.dart';
import '../bloc/section_see_all_event.dart';
import '../bloc/section_see_all_state.dart';

/// "See all" page for a single home-layout section. Fetches the full paginated
/// item list (GET /api/home-layout/sections/{id}) and renders the matching
/// card grid for the section [type] ('categories' / 'brands').
class SectionSeeAllPage extends StatefulWidget {
  final int sectionId;
  final String type;
  final String title;

  const SectionSeeAllPage({
    super.key,
    required this.sectionId,
    required this.type,
    this.title = '',
  });

  @override
  State<SectionSeeAllPage> createState() => _SectionSeeAllPageState();
}

class _SectionSeeAllPageState extends State<SectionSeeAllPage> {
  final ScrollController _scrollController = ScrollController();
  late final SectionSeeAllBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<SectionSeeAllBloc>()
      ..add(FetchSectionItems(sectionId: widget.sectionId, type: widget.type));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _bloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _bloc.add(const FetchMoreSectionItems());
    }
  }

  void _openListing({
    required ProductListingType type,
    required String? slug,
    String? title,
    String? logo,
  }) {
    if (slug == null || slug.isEmpty) return;
    GoRouter.of(context).push(AppRoutes.productListing, extra: {
      'type': type,
      'identifier': slug,
      'title': title ?? '',
      'logo': logo ?? '',
    });
  }

  Widget _buildShimmer(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 12,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.0,
        ),
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          return ShimmerWidget.rectangular(
            isBorder: true,
            borderRadius: 12.r,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: CustomScaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: BlocBuilder<SectionSeeAllBloc, SectionSeeAllState>(
          builder: (context, state) {
            log('Section See All State $state');
            if (state is SectionSeeAllLoading ||
                state is SectionSeeAllInitial) {
              return _buildShimmer(context);
            }
            if (state is SectionSeeAllFailed) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(state.error, textAlign: TextAlign.center),
                ),
              );
            }
            if (state is SectionSeeAllLoaded) {
              if (state.items.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)?.noData ?? 'No data',
                  ),
                );
              }
              return ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                children: [
                  _grid(state),
                  if (state.isLoadingMore)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _grid(SectionSeeAllLoaded state) {
    switch (state.type) {
      case 'categories':
        final tiles = state.items.whereType<CategoryData>().map((c) {
          return SampleTile(
            name: c.title ?? '',
            imageUrl: c.image ?? '',
            onTap: () => _openListing(
              type: ProductListingType.category,
              slug: c.slug,
              title: c.title,
              logo: c.image,
            ),
          );
        }).toList();
        return CategoryCardsGrid(categories: tiles);
      case 'brands':
        final tiles = state.items.whereType<BrandData>().map((b) {
          return SampleTile(
            name: b.title ?? '',
            imageUrl: b.logo ?? '',
            onTap: () => _openListing(
              type: ProductListingType.brand,
              slug: b.slug,
              title: b.title,
              logo: b.logo,
            ),
          );
        }).toList();
        return BrandStyleTwo(brands: tiles);
      default:
        return const SizedBox.shrink();
    }
  }
}
