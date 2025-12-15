import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gcr/studypal/Models/subject_model.dart';
import 'package:gcr/studypal/providers/teacher_provider.dart';
import 'package:gcr/studypal/teachers/upload_material_screen.dart';
import 'package:gcr/studypal/theme/app_colors.dart';
import 'file_viewer_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final SubjectModel subject;
  final bool isTeacher;

  const ClassDetailScreen({
    super.key,
    required this.subject,
    required this.isTeacher,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  String? _expandedDocId;
  final Map<String, String> _selectedFiles = {};

  Future<void> _editDeadline(
    BuildContext context,
    String materialId,
    DateTime? currentDeadline,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDeadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      await Provider.of<TeacherProvider>(context, listen: false).editMaterial(
        subjectId: widget.subject.id,
        materialId: materialId,
        deadline: picked,
        context: context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          widget.subject.subjectName,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (widget.isTeacher)
            IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // ---------- HEADER ----------
          Container(
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Text(
                  "Subject Code: ${widget.subject.subjectCode}",
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Instructor: ${widget.subject.teacherName}",
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // ---------- MATERIALS LIST ----------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.subject.id)
                  .collection('materials')
                  .orderBy('uploadedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          size: 60.sp,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 15.h),
                        Text(
                          "No materials uploaded yet",
                          style: GoogleFonts.poppins(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;

                    final fileName = data['fileName'] ?? 'Unknown File';
                    final fileUrl = data['fileUrl'] ?? '';
                    final title = data['title'] ?? 'Untitled';
                    final description = data['description'] ?? '';
                    final type = data['type'] ?? 'lecture';

                    final Timestamp? deadlineTs = data['deadline'];
                    final DateTime? deadline = deadlineTs?.toDate();
                    final formattedDeadline = deadline != null
                        ? DateFormat('MMM dd, yyyy').format(deadline)
                        : "No Deadline";

                    final isExpanded = _expandedDocId == docId;
                    final pickedFile = _selectedFiles[docId];

                    IconData fileIcon;
                    if (type == 'assignment') {
                      fileIcon = Icons.assignment_outlined;
                    } else if (fileName.toLowerCase().contains('.pdf')) {
                      fileIcon = Icons.picture_as_pdf;
                    } else if (fileName.toLowerCase().contains('.doc')) {
                      fileIcon = Icons.description;
                    } else if (fileName.toLowerCase().contains('.jpg') ||
                        fileName.toLowerCase().contains('.png')) {
                      fileIcon = Icons.image;
                    } else {
                      fileIcon = Icons.insert_drive_file;
                    }

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(fileIcon, color: AppColors.primary),
                            title: Text(title),
                            subtitle: Text(fileName),
                            trailing: type == 'assignment'
                                ? Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                  )
                                : const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              if (type == 'assignment') {
                                setState(() {
                                  _expandedDocId = isExpanded ? null : docId;
                                });
                              } else if (fileUrl.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FileViewerScreen(
                                      fileUrl: fileUrl,
                                      fileName: fileName,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isTeacher
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UploadMaterialScreen(subjectId: widget.subject.id),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              label: const Text("Upload Material"),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }
}
