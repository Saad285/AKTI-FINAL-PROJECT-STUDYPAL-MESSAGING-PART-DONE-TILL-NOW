import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gcr/studypal/common/classes_list_screen.dart';
import 'package:gcr/studypal/common/today_schedule_widget.dart';
import 'package:gcr/studypal/messages/unread_chats_card.dart';
import 'package:gcr/studypal/teachers/class_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gcr/studypal/theme/app_colors.dart';
import 'package:gcr/studypal/students/buildinfocard.dart';
import 'package:gcr/studypal/Authentication/loginpage.dart';

class Hometab extends StatefulWidget {
  const Hometab({super.key});

  @override
  State<Hometab> createState() => _HometabState();
}

class _HometabState extends State<Hometab> {
  late Future<DocumentSnapshot?> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _fetchUserData();
  }

  Future<DocumentSnapshot?> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    return FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color infoTextColor = Colors.white;

    return FutureBuilder<DocumentSnapshot?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        String userName = "Loading...";
        bool isTeacher = false;

        if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          userName = "Hello ${data['name'] ?? 'User'}";
          final role = data['role'];
          isTeacher =
              role != null && role.toString().toLowerCase() == 'teacher';
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {},
            ),
            title: Text(
              'StudyPal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20.sp,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: GestureDetector(
                  onTap: () => _logout(context),
                  child: CircleAvatar(
                    radius: 16.r,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- HEADER ----------
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 30.h),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Role: ${isTeacher ? 'Teacher' : 'Student'}',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30.h),

                // ---------- CONTENT ----------
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTeacher ? "My Dashboard" : "What's new",
                        style: GoogleFonts.poppins(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 18.h),

                      // INFO CARDS
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (isTeacher) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ClassesListScreen(),
                                  ),
                                );
                              }
                            },
                            child: IinfoCard(
                              title: isTeacher ? "Active" : "Upcoming",
                              number: isTeacher ? "3" : "7",
                              subtitle: isTeacher ? "classes" : "exams",
                              bgColor: const Color(0xFF757BC8),
                              textColor: infoTextColor,
                              width: 120,
                            ),
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: IinfoCard(
                              title: "Pending",
                              number: "16",
                              subtitle: isTeacher ? "grading" : "homeworks",
                              bgColor: const Color(0xFFFFB13D),
                              textColor: infoTextColor,
                              width: double.infinity,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 14.h),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (isTeacher) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CreateClassScreen(),
                                    ),
                                  );
                                }
                              },
                              child: IinfoCard(
                                title: isTeacher ? "Create" : "New",
                                number: isTeacher ? "+" : "3",
                                subtitle: isTeacher ? "new class" : "classes",
                                bgColor: isTeacher
                                    ? Colors.green
                                    : const Color(0xFFFFB13D),
                                textColor: infoTextColor,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          SizedBox(width: 14.w),
                          const UnreadChatsCard(),
                        ],
                      ),

                      SizedBox(height: 30.h),

                      Text(
                        "Today's schedule",
                        style: GoogleFonts.poppins(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 14.h),

                      const TodayScheduleWidget(),

                      SizedBox(height: 120.h),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
