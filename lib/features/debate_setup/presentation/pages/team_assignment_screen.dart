// // TODO: needs full rewrite — copied from old project (depends on sizer, deleted core/components/* and localization)
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:poi/core/app_cubit/app_cubit.dart';
// import 'package:poi/core/components/navigators.dart';
// import 'package:poi/core/constants/constants.dart';
// import 'package:poi/core/localization/l10n/context_localiztion.dart';
// import 'package:poi/features/debate_setup/presentation/bloc/debate_setup_cubit.dart';
// import 'package:poi/features/debate_setup/presentation/bloc/debate_setup_states.dart';
// import 'package:poi/features/debate_setup/presentation/widgets/team_card.dart';
// import 'package:sizer/sizer.dart';

// import '../../../../core/app_cubit/app_states.dart';
// import '../../../../core/theme/app_colors.dart';
// import 'motion_screen.dart';

// class TeamAssignmentScreen extends StatelessWidget {
// const TeamAssignmentScreen({super.key});

// @override
// Widget build(BuildContext context) {
// return BlocBuilder<AppCubit, AppStates>(
// builder: (context, state) {
// final appCubit = context.read<AppCubit>;
// final color = ThemedColors(appCubit.isLightTheme);
// final textTheme = Theme.of(context).textTheme;
// return BlocBuilder<DebateSetupCubit, DebateSetupStates>(
// builder: (context, state) {
// final cubit = context.read<DebateSetupCubit>;
// return Scaffold(
// appBar: AppBar(
// title: Text(
// context.loc.assign_debate_sides,
// style: TextStyle(
// color: textTheme.labelLarge?.color,
// fontSize: textTheme.labelLarge?.fontSize,
// fontWeight: textTheme.labelLarge?.fontWeight,
//),
//),
// actions: [
// IconButton(
// onPressed:  {
// appCubit.changeTheme(!appCubit.isLightTheme);
// },
// icon: Icon(appCubit.isLightTheme ? Icons.dark_mode_outlined: Icons.light_mode_outlined),
//),
// IconButton(
// onPressed:  {
// appCubit.changeLocale(appCubit.locale == "en" ? "ar": "en");
// },
// icon: Icon(Icons.translate),
//),
//],
//),
// body: Padding(
// padding: EdgeInsets.symmetric(vertical: 3.h),
// child: Column(
// mainAxisSize: MainAxisSize.max,
// children: [
// Text(
// context.loc.assign_debate_sides,
// style: TextStyle(color: textTheme.labelLarge?.color, fontSize: 22, fontWeight: textTheme.labelLarge?.fontWeight),
//),
// Expanded(
// flex: 4,
// child: GridView.count(
// crossAxisCount: 2,
// childAspectRatio: 0.7,
// padding: EdgeInsets.all(3.h),
// mainAxisSpacing: 3.h,
// crossAxisSpacing: 3.h,
// physics: NeverScrollableScrollPhysics,
// children: List.generate(cubit.currentTeams.length, (index) {
// DebateTeam team = DebateTeam(
// player1: "player${index * 10}",
// player2: "player${index * 10 + 1}",
// assignedSide: cubit.currentTeams[index],
//);
// return TeamCard(team: team, availableSides: cubit.allSides, color: color, textStyles: textTheme);
// }),
//),
//),
// Padding(
// padding: EdgeInsets.only(left: 10.w, right: 10.w, bottom: 3.h),
// child: Row(
// mainAxisAlignment: MainAxisAlignment.center,
// mainAxisSize: MainAxisSize.max,
// children: [
// Expanded(
// child: ClipRRect(
// borderRadius: BorderRadius.circular(widgetBorderRadius),
// child: ElevatedButton(
// onPressed:  {
// cubit.randomizeSides;
// },
// style: ElevatedButton.styleFrom(backgroundColor: color.secondary),
// child: Text(
// context.loc.random,
// style: TextStyle(
// color: color.primary,
// fontWeight: FontWeight.bold,
//)
//),
//),
//),
//),
// SizedBox(width: 5.w),
// Expanded(
// child: ClipRRect(
// borderRadius: BorderRadius.circular(widgetBorderRadius),
// child: ElevatedButton(
// onPressed:  {
// navigateTo(context, MotionScreen);
// },
// style: ElevatedButton.styleFrom(backgroundColor: color.red),
// child: Text(context.loc.next, style: TextStyle(color: AppColors.lighterColor, fontWeight: FontWeight.bold)),
//),
//),
//),
//],
//),
//),
//],
//),
//),
//);
// },
//);
// },
//);
// }
// }
