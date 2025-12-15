import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gcr/studypal/Models/subject_model.dart';
import 'package:gcr/studypal/teachers/class_screen.dart';
import 'package:gcr/studypal/theme/app_colors.dart';
import 'package:gcr/studypal/theme/animated_background.dart';
import 'package:gcr/studypal/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'class_detail_screen.dart';

class ClassesListScreen extends StatelessWidget {
  const ClassesListScreen({super.key});

  Future<bool> _isTeacher() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return false;
    return (doc.data() as Map<String, dynamic>)['role'] == 'teacher';
  }

  // --- DELETE FUNCTION ---
  Future<void> _deleteClass(String classId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Class deleted successfully")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error deleting class: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<bool>(
      future: _isTeacher(),
      builder: (context, roleSnapshot) {
        bool isTeacher = roleSnapshot.data ?? false;

        return AnimatedBackground(
          colors: AppTheme.primaryGradient,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                isTeacher ? "My Created Classes" : "All Classes",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
              ),
              backgroundColor: AppColors.primary,
              centerTitle: true,
              automaticallyImplyLeading: false,
            ),

            floatingActionButton: isTeacher
                ? Padding(
                    padding: EdgeInsets.only(bottom: 20.h),
                    child: FloatingActionButton(
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateClassScreen(),
                          ),
                        );
                      },
                    ),
                  )
                : null,

            body: StreamBuilder<QuerySnapshot>(
              stream: isTeacher
                  ? FirebaseFirestore.instance
                        .collection('classes')
                        .where('teacherId', isEqualTo: user?.uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots()
                  : FirebaseFirestore.instance
                        .collection('classes')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.class_outlined,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          isTeacher
                              ? "You haven't created any classes yet."
                              : "No classes available.",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    String classId = docs[index].id;

                    SubjectModel subject = SubjectModel(
                      id: classId,
                      subjectName: data['subjectName'] ?? 'Unknown',
                      subjectCode: data['subjectCode'] ?? '---',
                      teacherId: data['teacherId'] ?? '',
                      teacherName: data['teacherName'] ?? 'Teacher',
                    );

                    // --- [CHANGED] WRAP CARD IN DISMISSIBLE ---
                    return Dismissible(
                      key: Key(classId),
                      direction: isTeacher
                          ? DismissDirection
                                .endToStart // Swipe Left only
                          : DismissDirection.none, // Disable for students
                      // Background shown when swiping
                      background: Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.w),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),

                      // Confirmation Dialog
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Delete Class?"),
                              content: const Text(
                                "Are you sure you want to delete this class? This cannot be undone.",
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text("Delete"),
                                ),
                              ],
                            );
                          },
                        );
                      },

                      // Perform Delete
                      onDismissed: (direction) {
                        _deleteClass(classId, context);
                      },

                      child: Card(
                        elevation: 2,
                        margin: EdgeInsets.only(bottom: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16.w),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              subject.subjectName.isNotEmpty
                                  ? subject.subjectName
                                        .substring(0, 1)
                                        .toUpperCase()
                                  : "C",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            subject.subjectName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            "Code: ${subject.subjectCode} • ${subject.teacherName}",
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassDetailScreen(
                                  subject: subject,
                                  isTeacher: user?.uid == subject.teacherId,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
