import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/event_model.dart';

class HomeOverviewWidget extends StatelessWidget {
  final ApiService _api = ApiService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ScheduledEvent>>(
      future: _api.getEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final events = snapshot.data ?? [];
        final now = DateTime.now();
        final todayEvents = events.where((e) => 
          DateFormat('yyyy-MM-dd').format(e.startTime) == DateFormat('yyyy-MM-dd').format(now)
        ).toList();
        
        final upcomingCount = events.where((e) => e.startTime.isAfter(now)).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back!",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "You have ${todayEvents.length} tasks scheduled for today.",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              
              // Stats Row
              Row(
                children: [
                  _buildStatCard(
                    context, 
                    "Upcoming", 
                    upcomingCount.toString(), 
                    Icons.event_available, 
                    const Color(0xFF6366F1)
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    context, 
                    "Due Today", 
                    todayEvents.length.toString(), 
                    Icons.today, 
                    const Color(0xFFEC4899)
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Quick Glance", style: Theme.of(context).textTheme.titleLarge),
                  TextButton(onPressed: () {}, child: const Text("View All")),
                ],
              ),
              const SizedBox(height: 16),
              
              if (todayEvents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.coffee, size: 48, color: Colors.indigo.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        const Text("Nothing left for today!", style: TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                )
              else
                ...todayEvents.take(3).map((e) => _buildQuickEvent(e)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickEvent(ScheduledEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: event.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.bolt, color: event.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  "${DateFormat('h:mm a').format(event.startTime)} @ ${event.location.isEmpty ? 'General' : event.location}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
        ],
      ),
    );
  }
}
