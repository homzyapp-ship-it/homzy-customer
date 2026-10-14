import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_local/screens/home_page/home_layout/bloc/home_layout_bloc.dart';
import 'package:hyper_local/screens/home_page/home_layout/bloc/home_layout_state.dart';
import 'package:hyper_local/screens/home_page/home_layout/widgets/home_layout_body.dart';
import 'package:hyper_local/screens/home_page/widgets/home_loading_shimmer.dart';
import 'package:hyper_local/utils/widgets/custom_circular_progress_indicator.dart';
import 'package:hyper_local/utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/utils/widgets/empty_states_page.dart';
import 'package:hyper_local/l10n/app_localizations.dart';

class HomeTabContent extends StatelessWidget {
  final String categorySlug;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;

  const HomeTabContent({
    super.key,
    required this.categorySlug,
    required this.onRefresh,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      child: BlocBuilder<HomeLayoutBloc, HomeLayoutState>(
        builder: (context, state) {
          if (state is HomeLayoutLoaded) {
            if (state.sections.isEmpty) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: NoProductPage(
                        onRetry: onRetry,
                        title: categorySlug.isEmpty
                            ? (AppLocalizations.of(context)?.noSectionFound ??
                                'No Section Found')
                            : null,
                      ),
                    ),
                  ),
                ],
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: HomeLayoutBody(sections: state.sections),
                ),
                if (state.isLoadingMore)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    sliver: const SliverToBoxAdapter(
                      child: Center(
                        child: CustomCircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            );
          }
          if (state is HomeLayoutFailed) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: NoProductPage(
                      onRetry: onRetry,
                      title: categorySlug.isEmpty
                          ? (AppLocalizations.of(context)?.noSectionFound ??
                              'No Section Found')
                          : null,
                    ),
                  ),
                ),
              ],
            );
          }
          return const CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: HomeLoadingShimmer(),
              ),
            ],
          );
        },
      ),
    );
  }
}
