import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/helper.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_state.dart';
import 'package:hyper_local/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';

class FreeDeliveryCartBanner extends StatelessWidget {
  final int cartItemCount;
  final CartState cartState;

  const FreeDeliveryCartBanner({
    super.key,
    required this.cartItemCount,
    required this.cartState,
  });

  @override
  Widget build(BuildContext context) {
    double freeDeliveryAmount = 0.0;
    double itemsTotal = 0.0;

    final getUserCartState = context.read<GetUserCartBloc>().state;
    if (getUserCartState is GetUserCartLoaded && getUserCartState.cartData.isNotEmpty) {
      freeDeliveryAmount = getUserCartState.cartData.first.data?.deliveryZone?.freeDeliveryAmount?.toDouble() ?? 0.0;
      itemsTotal = getUserCartState.cartData.first.data?.paymentSummary?.itemsTotal?.toDouble() ?? 0.0;
    }

    if (cartState is CartLoaded) {
      itemsTotal = (cartState as CartLoaded).totalAmount;
    }

    final currency = AppHelpers.currency;
    final neededAmount = freeDeliveryAmount - itemsTotal;
    final isFreeDelivery = freeDeliveryAmount > 0 && itemsTotal >= freeDeliveryAmount;
    final progress = freeDeliveryAmount > 0 ? (itemsTotal / freeDeliveryAmount).clamp(0.0, 1.0) : 0.0;

    final cartItem = cartState is CartLoaded && (cartState as CartLoaded).items.isNotEmpty
        ? (cartState as CartLoaded).items.first
        : null;
    final imageUrl = cartItem?.image ?? '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      height: 72.h,
      child: Row(
        children: [
          // Left Delivery Status Card
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFF303440),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Scooter Icon in Progress Circle
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 3.r,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        Icon(
                          Icons.two_wheeler_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isFreeDelivery ? 'FREE Delivery Unlocked!' : 'Unlock free delivery',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          isFreeDelivery
                              ? 'Congratulations! Free delivery on this order.'
                              : 'Shop for $currency${neededAmount.toStringAsFixed(0)} more',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Right Cart Pill
          GestureDetector(
            onTap: () {
              GoRouter.of(context).push(AppRoutes.cart);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFC2A68),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFC2A68).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Thumbnail
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding: EdgeInsets.all(4.r),
                    child: imageUrl.isNotEmpty
                        ? CustomImageContainer(
                            imagePath: imageUrl,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(8.r),
                            errorWidget: Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.grey[400],
                              size: 24.sp,
                            ),
                          )
                        : Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.grey[400],
                            size: 24.sp,
                          ),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '$cartItemCount item${cartItemCount > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
