import 'package:flutter/material.dart';

// const String SERVER_FAILURE_MESSAGE = 'Please try again later .';
// const String EMPTY_CACHE_FAILURE_MESSAGE = 'No Data';
// const String OFFLINE_FAILURE_MESSAGE = 'Please Check your Internet Connection';
// const String UNEXPECTED_FAILURE_MESSAGE = 'UNEXPECTED_FAILURE_MESSAGE';
const String SERVER_FAILURE_MESSAGE = 'يرجى المحاولة مرة أخرى لاحقاً.';
const String EMPTY_CACHE_FAILURE_MESSAGE = 'لا توجد بيانات';
const String OFFLINE_FAILURE_MESSAGE = 'يرجى التحقق من اتصالك بالإنترنت';
const String UNEXPECTED_FAILURE_MESSAGE = 'خطأ غير متوقع';
const String ADD_POST_SUCCESS_MESSAGE = 'Post added successfully';
const String Update_POST_SUCCESS_MESSAGE = 'Post updated successfully';
const String Delete_POST_SUCCESS_MESSAGE = 'Post deleted successfully';
const String LOGIN_SUCCESS_MESSAGE = 'تم تسجيل الدخول بنجاح';

RegExp EmailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');

const double widgetBorderRadius = 20;

Locale get englishLocale => const Locale('en');

Locale get arabicLocale => const Locale('ar');
