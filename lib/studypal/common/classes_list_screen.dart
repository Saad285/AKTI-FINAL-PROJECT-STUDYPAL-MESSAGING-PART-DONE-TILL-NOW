import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// IMPORTS
import 'package:gcr/studypal/teachers/class_screen.dart'; // For creating classes
import 'package:gcr/studypal/common/class_detail_screen.dart'; // <--- VERIFY THIS PATH
import 'package:gcr/studypal/Models/subject_model.dart'; // <--- VERIFY THIS PATH
import '../theme/app_colors.dart';

class ClassesListScreen extends StatelessWidget {
  const ClassesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          "My Created Classes",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Floating Action Button to Create Class
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateClassScreen()),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .where('teacherId', isEqualTo: user?.uid)
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
              child: Text(
                "No classes found. Tap + to create one.",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }

          final classes = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              var data = classes[index].data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.class_, color: AppColors.primary),
                  ),
                  title: Text(
                    data['subjectName'] ?? 'No Name',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    data['subjectCode'] ?? '',
                    style: GoogleFonts.poppins(),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),

                  // --- CLICK EVENT ADDED HERE ---
                  onTap: () {
                    // Create a SubjectModel from the Firestore data
                    // Ensure your SubjectModel constructor matches these fields!
                    SubjectModel subject = SubjectModel(
                      id: data['classId'],
                      subjectName: data['subjectName'],
                      subjectCode: data['subjectCode'],
                      teacherName: data['teacherName'],
                      // Add other fields if your model requires them
                    );

                    // Navigate to the Detail Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassDetailScreen(
                          subject: subject,
                          isTeacher:
                              true, // Since this is the "My Created Classes" list
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
