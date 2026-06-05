// // TODO: needs full rewrite — copied from old project (depends on sizer and deleted core/components/*)
// import 'package:flutter/material.dart';
// import 'package:poi/core/components/custom_dialog.dart';
// import 'package:poi/core/components/default_text_button.dart';
// import 'package:poi/core/constants/constants.dart';
// import 'package:poi/core/localization/l10n/context_localiztion.dart';
// import 'package:poi/core/theme/app_colors.dart';
// import 'package:sizer/sizer.dart';

// class NewMotionDialog extends StatelessWidget {
//   final ThemedColors themedColor;
//   final String title;
//   final TextEditingController titleController;
//   final List<String> allTopics;
//   final List<String> selectedTopics;
//   final void Function(String topic) toggleTopicFunction;
//   const NewMotionDialog({
//     super.key,
//     required this.themedColor,
//     required this.title,
//     required this.titleController,
//     required this.allTopics,
//     required this.selectedTopics,
//     required this.toggleTopicFunction,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return CustomDialog(
//         width: 65.w,
//         height: 50.h,
//         firstColor: themedColor.blue,
//         secondColor: themedColor.red,
//         bodyColor: themedColor.primary,
//         title: title,
//         body: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             // Motion title
//             defaultTextFormField(
//                 context,
//                 controller: titleController,
//                 hintText: context.loc.motion,
//                 textColor: themedColor.secondary,
//                 keyboardType: TextInputType.text,
//                 mainColor: themedColor.secondary,
//                 maxLength: 200,
//                 maxLines: 10,
//                 radiusBorder: widgetBorderRadius
//             ),
//             SizedBox(height: 3.h),
//             // Topics selection
//             Text(
//               "${context.loc.select_topics}:",
//               style: TextStyle(
//                   color: themedColor.secondary,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w400
//               ),
//               textAlign: TextAlign.start,
//               maxLines: 2,
//             ),
//             SizedBox(height: 1.5.h),
//             Row(
//               children: [
//                 SizedBox(width: 5.w,),
//                 Expanded(child: Container(height: 0.5, color: themedColor.secondary.withValues(alpha: 0.7),)),
//               ],
//             ),
//             Expanded(
//               child: ListView.separated(
//                 shrinkWrap: false,
//                 itemBuilder: (context, index){
//                   final topic = allTopics[index];
//                   final isSelected = selectedTopics.contains(topic);
//                   return CheckboxListTile(
//                     activeColor: themedColor.red,
//                     title: Text(topic, style: TextStyle(color: themedColor.secondary)),
//                     value: isSelected,
//                     onChanged: (val) {
//                       if (val == true) {
//                         toggleTopicFunction(topic);
//                       } else {
//                         toggleTopicFunction(topic);
//                       }
//                     },
//                   );
//                 },
//                 separatorBuilder: (context, state) => Row(
//                   children: [
//                     SizedBox(width: 5.w,),
//                     Expanded(child: Container(height: 0.5, color: themedColor.secondary.withValues(alpha: 0.7),)),
//                   ],
//                 ),
//                 itemCount: allTopics.length,
//               ),
//             ),
//             SizedBox(height: 1.5.h),
//             Row(
//               children: [
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(widgetBorderRadius),
//                     child: ElevatedButton(
//                       onPressed: () {
//                         //TODO
//                       },
//                       style: ElevatedButton.styleFrom(backgroundColor: themedColor.blue),
//                       child: Text(context.loc.submit, style: TextStyle(color: AppColors.lighterColor, fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//     );
//   }
// }
