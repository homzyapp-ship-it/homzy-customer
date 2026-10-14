# Guide: Removing the Old Home Screen UI Components

When you are ready to completely remove the old static UI code and components in a future release, follow these steps to clean up the codebase.

---

## 1. Delete Unused Files and Folders
Delete the following files and directories from the repository:

- **BLoC & Repos**:
  - `lib/screens/home_page/bloc/feature_section_product/` (Entire folder containing bloc, event, and state)
  - `lib/screens/home_page/repo/feature_section_product_repo.dart`

- **Widgets**:
  - `lib/screens/home_page/widgets/product_feature_section_widget.dart`
  - `lib/screens/home_page/widgets/sections/home_tab_content_section.dart`
  - `lib/screens/home_page/widgets/sections/home_featured_section.dart`

---

## 2. Update Configuration Files

### `lib/config/global.dart`
- Remove the configuration flag:
  ```dart
  static bool wantNewUI = true;
  ```

### `lib/config/dependency_injection_container.dart`
- Remove the import:
  ```dart
  import '../screens/home_page/bloc/feature_section_product/feature_section_product_bloc.dart';
  ```
- Remove the DI registration:
  ```dart
  getIt.registerLazySingleton(() => FeatureSectionProductBloc());
  ```

### `lib/config/global_bloc_providers.dart`
- Remove the import:
  ```dart
  import 'package:hyper_local/screens/home_page/bloc/feature_section_product/feature_section_product_bloc.dart';
  ```
- Remove the BlocProvider registration:
  ```dart
  BlocProvider<FeatureSectionProductBloc>.value(value: getIt<FeatureSectionProductBloc>()),
  ```

---

## 3. Clean up the Home Screen View (`lib/screens/home_page/view/home_page.dart`)

### Imports
Remove the imports that correspond to the deleted files:
```dart
import '../bloc/feature_section_product/feature_section_product_bloc.dart';
import '../bloc/feature_section_product/feature_section_product_event.dart';
import '../bloc/feature_section_product/feature_section_product_state.dart';
import '../widgets/product_feature_section_widget.dart';
import '../widgets/sections/home_tab_content_section.dart';
import '../widgets/banner_slider.dart';
import '../widgets/home_featured_placeholder.dart';
import '../bloc/sub_category/sub_category_bloc.dart';
import '../bloc/sub_category/sub_category_event.dart';
import '../bloc/brands/brands_bloc.dart';
import '../bloc/banner/banner_bloc.dart';
import '../bloc/banner/banner_event.dart';
```

### State Fields
Remove the unused pagination tracker map inside `_HomePageState`:
```dart
final Map<int, bool> _isLoadingMoreForTab = {};
```

### Tab Change Listeners
Remove the clear-cache blocks from `_onTabChanged()` and `_ensureValidTabIndex()`.
- **In `_onTabChanged()`**: Remove:
  ```dart
  if (!Global.wantNewUI) {
    context.read<FeatureSectionProductBloc>().add(ClearFeatureSectionProducts());
  }
  ```
- **In `_ensureValidTabIndex()`**: Remove:
  ```dart
  if (!Global.wantNewUI) {
    // Clear feature section products to prevent showing old data
    context.read<FeatureSectionProductBloc>().add(ClearFeatureSectionProducts());
  }
  ```

### API Calls
Revert `apiCalls()` to only dispatch events for the new `HomeLayoutBloc`:
```dart
  void apiCalls(String slug) async {
    final updatedSlug = (_canUseTabController && _tabController.index != 0) ? slug : '';

    // Consolidated Home API call via HomeLayoutBloc
    context.read<HomeLayoutBloc>().add(FetchHomeLayout(categorySlug: updatedSlug));

    // Other support calls
    context.read<GetUserCartBloc>().add(FetchUserCart());
    context.read<GetAddressListBloc>().add(FetchUserAddressList());
    context.read<NotificationBloc>().add(FetchNotifications());

    await Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        context.read<SettingsBloc>().add(FetchSettingsData(context: context));
      }
    });
  }
```

### Building Tab Content
Revert `_buildHomeTabContent()` to return the new layout unconditionally:
```dart
  Widget _buildHomeTabContent({required String categorySlug}) {
    return HomeTabContent(
      categorySlug: categorySlug,
      onRefresh: () async {
        apiCalls(categorySlug);
        if (categorySlug.isEmpty) {
          _applyHomeGeneralSettingsToAppBar();
        } else {
          final category = _categories.firstWhere(
            (item) => item.slug == categorySlug,
            orElse: () => CategoryData(),
          );
          _applyCategoryAppBar(category);
        }
        context.read<CategoryBloc>().add(FetchCategory(context: context));
      },
      onRetry: () {
        apiCalls(categorySlug);
      },
    );
  }
```

### Pagination Loading
Revert `_loadMoreForCurrentTab()` to only trigger `HomeLayoutBloc` additions:
```dart
  void _loadMoreForCurrentTab(int tabIndex) {
    final state = context.read<HomeLayoutBloc>().state;
    if (state is HomeLayoutLoaded &&
        !state.hasReachedMax &&
        !state.isLoadingMore) {
      context.read<HomeLayoutBloc>().add(const FetchMoreHomeLayout());
    }
  }
```
