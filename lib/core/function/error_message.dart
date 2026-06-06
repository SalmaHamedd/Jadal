import '../error/failures.dart';

String mapFailureToMessage(Failure failure) {
  switch (failure.runtimeType) {
    case ServerFailure _:
      return 'حدث خطأ ما أثناء جلب المعلومات';
    case EmptyCacheFailure _:
      return 'لا توجد بيانات مخزنة';
    case OfflineFailure _:
      return 'خطأ في الاتصال بالانترنت';
    case NetworkFailure _:
      return 'خطأ في الاتصال';
    case AuthFailure _:
      return failure.message;
    default:
      return 'خطأ غير متوقع أعد المحاولة لاحقاً';
  }
}
