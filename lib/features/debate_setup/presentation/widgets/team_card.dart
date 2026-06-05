// // TODO: needs full rewrite — copied from old project (depends on sizer and old poi imports)
// import 'package:flutter/material.dart';
// import 'package:poi/core/constants/constants.dart';
// import 'package:poi/core/theme/app_colors.dart';
// import 'package:sizer/sizer.dart';

// class DebateTeam {
//   final String player1;
//   final String player2;
//   String assignedSide;

//   DebateTeam({
//     required this.player1,
//     required this.player2,
//     required this.assignedSide,
//   });
// }

// class TeamCard extends StatelessWidget {
//   final DebateTeam team;
//   final List<String> availableSides;
//   final ThemedColors color;
//   final TextTheme textStyles;

//   const TeamCard({
//     super.key,
//     required this.team,
//     required this.availableSides,
//     required this.color,
//     required this.textStyles,
//   });

//   @override
//   Widget build(BuildContext context) {
//     Color sideColor = AppColors.getSideColor(team.assignedSide);
//     return Container(
//       decoration: BoxDecoration(
//         color: color.darkerOrLighter,
//         border: Border.all(
//             color: sideColor,
//             width: 5
//         ),
//         borderRadius: BorderRadius.circular(widgetBorderRadius),
//       ),
//       child: Stack(
//         children: [
//           /// Content in center
//           Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   team.assignedSide.toUpperCase(),
//                   style: TextStyle(
//                     fontSize: 42,
//                     fontWeight: FontWeight.bold,
//                     color: textStyles.displayLarge!.color,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Padding(
//                   padding: EdgeInsets.all(3.w),
//                   child: Text(
//                     '${team.player1} & ${team.player2}',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: textStyles.displayLarge?.color,
//                     ),
//                     textAlign: TextAlign.center,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
