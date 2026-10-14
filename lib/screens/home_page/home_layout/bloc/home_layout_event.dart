import 'package:equatable/equatable.dart';

abstract class HomeLayoutEvent extends Equatable {
  const HomeLayoutEvent();

  @override
  List<Object?> get props => [];
}

class FetchHomeLayout extends HomeLayoutEvent {
  final String categorySlug;
  const FetchHomeLayout({this.categorySlug = ''});

  @override
  List<Object?> get props => [categorySlug];
}

class FetchMoreHomeLayout extends HomeLayoutEvent {
  const FetchMoreHomeLayout();
}
