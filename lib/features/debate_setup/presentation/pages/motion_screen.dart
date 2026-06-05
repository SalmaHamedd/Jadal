// // TODO: needs full rewrite — copied from old project (depends on sizer, dropdown_button2, deleted core/components/* and localization)
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:poi/core/app_cubit/app_cubit.dart';
// import 'package:poi/core/components/default_text_button.dart';
// import 'package:poi/core/components/navigators.dart';
// import 'package:poi/core/constants/constants.dart';
// import 'package:poi/core/localization/l10n/context_localiztion.dart';
// import 'package:poi/features/debate_setup/presentation/bloc/debate_setup_cubit.dart';
// import 'package:poi/features/debate_setup/presentation/bloc/debate_setup_states.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';
// import 'package:poi/features/debate_setup/presentation/widgets/filter_dialog.dart';
// import 'package:poi/features/debate_setup/presentation/widgets/new_motion_dialog.dart';
// import 'package:sizer/sizer.dart';
// import '../../../../core/app_cubit/app_states.dart';
// import '../../../../core/theme/app_colors.dart';

// class MotionScreen extends StatelessWidget {
//   MotionScreen({super.key});
//   final TextEditingController searchFormController = TextEditingController();
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<AppCubit, AppStates>(
//       builder: (context, state) {
//         final appCubit = context.read<AppCubit>();
//         final color = ThemedColors(appCubit.isLightTheme);
//         final textTheme = Theme.of(context).textTheme;
//         return BlocBuilder<DebateSetupCubit, DebateSetupStates>(
//           builder: (context, state) {
//             final cubit = context.read<DebateSetupCubit>();

//             return Scaffold(
//               appBar: AppBar(
//                 title: Text(
//                   context.loc.select_debate_motion,
//                   style: TextStyle(
//                     color: textTheme.labelLarge?.color,
//                     fontSize: textTheme.labelLarge?.fontSize,
//                     fontWeight: textTheme.labelLarge?.fontWeight,
//                   ),
//                 ),
//                 actions: [
//                   IconButton(
//                     onPressed: () {
//                       appCubit.changeTheme(!appCubit.isLightTheme);
//                     },
//                     icon: Icon(appCubit.isLightTheme ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
//                   ),
//                   IconButton(
//                     onPressed: () {
//                       appCubit.changeLocale(appCubit.locale == "en" ? "ar" : "en");
//                     },
//                     icon: Icon(Icons.translate),
//                   ),
//                 ],
//               ),
//               body: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 4.w),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.max,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Expanded(
//                             child: SingleChildScrollView(
//                               child: Column(
//                                 children: [
//                                   Row(
//                                     children: [
//                                       Expanded(
//                                         child: defaultTextFormField(
//                                           context,
//                                           controller: searchFormController,
//                                           mainColor: color.secondary,
//                                           textColor: color.secondary,
//                                           keyboardType: TextInputType.text,
//                                           hintText: context.loc.search_motion,
//                                           prefix: Icon(Icons.search, color: color.secondary),
//                                           onChanged: (query) {
//                                             cubit.searchMotions(query);
//                                           },
//                                         ),
//                                       ),
//                                       SizedBox(width: 0.2.w),
//                                       IconButton(
//                                         icon: Stack(
//                                           alignment: AlignmentDirectional.topEnd,
//                                           children: [
//                                             Icon(Icons.filter_alt_outlined, size: 25, color: color.secondary,),
//                                             if(cubit.selectedTopics.isNotEmpty)
//                                               Container(
//                                                 decoration: BoxDecoration(
//                                                   borderRadius: BorderRadius.circular(100),
//                                                   color: color.red,
//                                                 ),
//                                                 height: 7.5,
//                                                 width: 7.5,
//                                               ),
//                                           ],
//                                         ),
//                                         onPressed: () async {
//                                           cubit.selectedTopicsCopy = cubit.selectedTopics.sublist(0);
//                                           showDialog(
//                                             context: context,
//                                             builder:
//                                                 (_) => BlocBuilder<DebateSetupCubit, DebateSetupStates>(
//                                               builder: (context, state) {
//                                                 final cubit = context.read<DebateSetupCubit>();
//                                                 return FilterDialog(
//                                                   themedColor: color,
//                                                   title: context.loc.filter_motion,
//                                                   allTopics: cubit.allTopics,
//                                                   selectedTopics: cubit.selectedTopicsCopy,
//                                                   toggleTopicFunction: (topic) => cubit.toggleTopic(topic),
//                                                   appFilterFunction: () => cubit.applyFilters(),
//                                                 );
//                                               },
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                       SizedBox(width: 0.2.w),
//                                       IconButton(
//                                         icon: Icon(Icons.add_circle_outline_rounded, size: 25, color: color.blue,),
//                                         onPressed: () async {
//                                           showDialog(
//                                             context: context,
//                                             builder: (_) {
//                                               final TextEditingController titleController = TextEditingController();
//                                               return BlocBuilder<DebateSetupCubit, DebateSetupStates>(
//                                                 builder: (context, state) {
//                                                   return NewMotionDialog(
//                                                     themedColor: color,
//                                                     title: context.loc.motion,
//                                                     titleController: titleController,
//                                                     allTopics: cubit.allTopics,
//                                                     selectedTopics: cubit.newMotionSelectedTopics,
//                                                     toggleTopicFunction: cubit.addTopicToNewMotion,
//                                                   );
//                                                 },
//                                               );
//                                             },
//                                           );
//                                         },
//                                       ),
//                                     ],
//                                   ),
//                                   SizedBox(height: 2.h),
//                                   ListView.builder(
//                                     physics: NeverScrollableScrollPhysics(),
//                                     shrinkWrap: true,
//                                     itemCount: cubit.filteredMotions.length,
//                                     itemBuilder: (context, index) {
//                                       final motion = cubit.filteredMotions[index];
//                                       return ClipRRect(
//                                         borderRadius: BorderRadius.circular(widgetBorderRadius),
//                                         child: Card(
//                                           margin: EdgeInsets.symmetric(vertical: 0.6.h, horizontal: 4.w),
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius: BorderRadius.circular(widgetBorderRadius),
//                                           ),
//                                           child: ListTile(
//                                             tileColor: motion == cubit.selectedMotion
//                                                 ? ThemedColors(!appCubit.isLightTheme).darkerOrLighter
//                                                 : color.darkerOrLighter,
//                                             title: Text(
//                                               motion.title,
//                                               style: textTheme.labelLarge?.copyWith(
//                                                 color: motion == cubit.selectedMotion ? color.primary : color.secondary,
//                                               ),
//                                             ),
//                                             subtitle: Text(
//                                               motion.topics.join(", "),
//                                               textAlign: TextAlign.end,
//                                               style: textTheme.bodySmall?.copyWith(
//                                                 color: motion == cubit.selectedMotion
//                                                     ? ThemedColors(!appCubit.isLightTheme).blue
//                                                     : color.blue,
//                                               ),
//                                             ),
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius: BorderRadius.circular(widgetBorderRadius),
//                                             ),
//                                             onTap: () {
//                                               cubit.selectMotion(motion);
//                                             }, // Implement selectMotion
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           SizedBox(
//                             height: 8.h,
//                             child: Padding(
//                               padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h,),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 mainAxisSize: MainAxisSize.max,
//                                 crossAxisAlignment: CrossAxisAlignment.center,
//                                 children: [
//                                   Expanded(
//                                     child: ClipRRect(
//                                       borderRadius: BorderRadius.circular(widgetBorderRadius),
//                                       child: ElevatedButton(
//                                         onPressed: () {
//                                           cubit.randomizeMotion();
//                                         },
//                                         style: ElevatedButton.styleFrom(backgroundColor: color.secondary),
//                                         child: Text(context.loc.random, style: TextStyle(color: color.primary, fontWeight: FontWeight.bold)),
//                                       ),
//                                     ),
//                                   ),
//                                   SizedBox(width: 5.w),
//                                   Expanded(
//                                     child: ClipRRect(
//                                       borderRadius: BorderRadius.circular(widgetBorderRadius),
//                                       child: ElevatedButton(
//                                         onPressed: () {
//                                           //TODO: bind with backend also in new motion
//                                         },
//                                         style: ElevatedButton.styleFrom(backgroundColor: color.red),
//                                         child: Text(context.loc.submit, style: TextStyle(color: AppColors.lighterColor, fontWeight: FontWeight.bold)),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }
