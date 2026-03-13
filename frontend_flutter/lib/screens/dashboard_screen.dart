import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/event_list_widget.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _auth = AuthService();
  int _currentIndex = 0;
  final GlobalKey<CalendarWidgetState> _calendarKey = GlobalKey<CalendarWidgetState>();

  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vibrant Scheduler"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          CalendarWidget(
            key: _calendarKey,
            onEventUpdated: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            },
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.list_alt, color: Colors.indigo, size: 28),
                      const SizedBox(width: 8),
                      Text("Upcoming Schedule", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo[900])),
                    ],
                  ),
                ),
                EventListWidget(
                  onUpdate: () => _calendarKey.currentState?.refresh(),
                  onEdit: (event) {
                    setState(() => _currentIndex = 0);
                    Future.delayed(const Duration(milliseconds: 100), () {
                      _calendarKey.currentState?.showEditDialog(event: event);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.indigo,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Upcoming'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        onPressed: () {
          if (_currentIndex != 0) setState(() => _currentIndex = 0);
          _calendarKey.currentState?.addNewEvent();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
