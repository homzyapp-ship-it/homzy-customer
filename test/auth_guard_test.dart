// import 'package:flutter_test/flutter_test.dart';
// import 'package:hyper_local/config/global.dart';
// import 'package:hyper_local/model/user_data_model/user_data_model.dart';
// import 'package:hyper_local/services/auth_guard.dart';
//
// void main() {
//   test('AuthGuard.isAppleUser returns false when userData is null', () {
//     expect(AuthGuard.isAppleUser(), isFalse);
//   });
//
//   test('AuthGuard.isAppleUser returns false when provider is email/google', () {
//     final userData = UserDataModel(
//       token: 'fake-token',
//       userId: '123',
//       name: 'Test User',
//       email: 'test@example.com',
//       mobile: '1234567890',
//       country: 'US',
//       iso2: 'US',
//       profileImage: '',
//       referralCode: 'REF123',
//       language: 'en',
//       authProvider: 'google',
//     );
//     Global.userDataNotifier.value = userData;
//
//     expect(AuthGuard.isAppleUser(), isFalse);
//   });
//
//   test('AuthGuard.isAppleUser returns true when provider is apple', () {
//     final userData = UserDataModel(
//       token: 'fake-token',
//       userId: '123',
//       name: 'Test User',
//       email: 'test@example.com',
//       mobile: '1234567890',
//       country: 'US',
//       iso2: 'US',
//       profileImage: '',
//       referralCode: 'REF123',
//       language: 'en',
//       authProvider: 'apple',
//     );
//     Global.userDataNotifier.value = userData;
//
//     expect(AuthGuard.isAppleUser(), isTrue);
//   });
//
//   test('AuthGuard.isAppleUser returns true when provider is apple_login', () {
//     final userData = UserDataModel(
//       token: 'fake-token',
//       userId: '123',
//       name: 'Test User',
//       email: 'test@example.com',
//       mobile: '1234567890',
//       country: 'US',
//       iso2: 'US',
//       profileImage: '',
//       referralCode: 'REF123',
//       language: 'en',
//       authProvider: 'apple_login',
//     );
//     Global.userDataNotifier.value = userData;
//
//     expect(AuthGuard.isAppleUser(), isTrue);
//   });
//
//   test('AuthGuard.isAppleUser returns true when provider is apple.com', () {
//     final userData = UserDataModel(
//       token: 'fake-token',
//       userId: '123',
//       name: 'Test User',
//       email: 'test@example.com',
//       mobile: '1234567890',
//       country: 'US',
//       iso2: 'US',
//       profileImage: '',
//       referralCode: 'REF123',
//       language: 'en',
//       authProvider: 'apple.com',
//     );
//     Global.userDataNotifier.value = userData;
//
//     expect(AuthGuard.isAppleUser(), isTrue);
//   });
// }
