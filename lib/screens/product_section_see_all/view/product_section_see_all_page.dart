import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:hyper_local/config/dependency_injection_container.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:hyper_local/utils/widgets/custom_shimmer.dart';
import 'package:hyper_local/utils/widgets/staggered_list_animator.dart';

import '../../../l10n/app_localizations.dart';
import '../../../router/app_routes.dart';
import '../../home_page/home_layout/widgets/home_layout_product_card.dart';
import '../bloc/product_section_see_all_bloc.dart';
import '../bloc/product_section_see_all_event.dart';
import '../bloc/product_section_see_all_state.dart';

class ProductSectionSeeAllPage extends StatefulWidget {
  final int sectionId;
  final String title;

  const ProductSectionSeeAllPage({
    super.key,
    required this.sectionId,
    this.title = '',
  });

  @override
  State<ProductSectionSeeAllPage> createState() => _ProductSectionSeeAllPageState();
}

class _ProductSectionSeeAllPageState extends State<ProductSectionSeeAllPage> {
  final ScrollController _scrollController = ScrollController();
  late final ProductSectionSeeAllBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ProductSectionSeeAllBloc>()..add(FetchProductSectionItems(sectionId: widget.sectionId));
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
      _bloc.add(const FetchMoreProductSectionItems());
    }
  }

  Widget _buildShimmer(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 16.h),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          mainAxisExtent: 210.h,
        ),
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ShimmerWidget.rectangular(
                  isBorder: true,
                  borderRadius: 12.r,
                ),
              ),
              SizedBox(height: 8.h),
              ShimmerWidget.rectangular(
                isBorder: true,
                height: 12.h,
                width: 70.w,
                borderRadius: 4.r,
              ),
              SizedBox(height: 4.h),
              ShimmerWidget.rectangular(
                isBorder: true,
                height: 10.h,
                width: 40.w,
                borderRadius: 4.r,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(HeroiconsOutline.magnifyingGlass),
            onPressed: () {
              GoRouter.of(context).push(AppRoutes.search);
            },
          ),
        ],
      ),
      showViewCart: true,
      showAppBar: true,
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<ProductSectionSeeAllBloc, ProductSectionSeeAllState>(
          builder: (context, state) {
            if (state is ProductSectionSeeAllLoading || state is ProductSectionSeeAllInitial) {
              return _buildShimmer(context);
            }
            if (state is ProductSectionSeeAllFailed) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Text(state.error, textAlign: TextAlign.center),
                ),
              );
            }
            if (state is ProductSectionSeeAllLoaded) {
              if (state.items.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)?.noData ?? 'No data',
                  ),
                );
              }
              return CustomRefreshIndicator(
                onRefresh: () async {
                  context.read<ProductSectionSeeAllBloc>().add(FetchProductSectionItems(sectionId: widget.sectionId));
                },
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.w),
                      child: StaggeredListAnimator(
                        type: StaggeredListType.gridView,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 5.w,
                          mainAxisSpacing: 12.h,
                          mainAxisExtent: 230.h,
                        ),
                        columnCount: 3,
                        children: state.items.map((item) => HomeLayoutProductCard(data: item)).toList(),
                      ),
                    ),
                    if (state.isLoadingMore)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
