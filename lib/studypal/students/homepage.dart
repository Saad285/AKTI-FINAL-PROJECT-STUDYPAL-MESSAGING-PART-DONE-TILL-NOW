import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gcr/studypal/chatbot/chat_bot_screen.dart';
import 'package:gcr/studypal/common/classes_list_screen.dart';
import 'package:gcr/studypal/messages/messages_screen.dart';
import 'package:gcr/studypal/students/hometab.dart';
import 'package:gcr/studypal/theme/app_colors.dart';
import 'package:gcr/studypal/theme/app_theme.dart';

class StudentHomepage extends StatefulWidget {
  const StudentHomepage({super.key});

  @override
  State<StudentHomepage> createState() => _StudentHomepageState();
}

class _StudentHomepageState extends State<StudentHomepage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Hometab(),
    const MessagesScreen(),
    const ChatBotScreen(),
    const Center(child: Text("Reminders Content")),

    const ClassesListScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_selectedIndex],

      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 40.h),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50.r),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(50.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 25,
                  spreadRadius: 1,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Transform.translate(
              offset: const Offset(0.0, 4.0),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white.withOpacity(0.6),
                selectedFontSize: 0.0,
                unselectedFontSize: 0.0,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined, size: 28),
                    activeIcon: Icon(Icons.home, size: 32),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble_outline, size: 28),
                    activeIcon: Icon(Icons.chat_bubble, size: 32),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.smart_toy_outlined, size: 28),
                    activeIcon: Icon(Icons.smart_toy, size: 32),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.notifications_outlined, size: 28),
                    activeIcon: Icon(Icons.notifications, size: 32),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.book_outlined, size: 28),
                    activeIcon: Icon(Icons.book, size: 32),
                    label: '',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
