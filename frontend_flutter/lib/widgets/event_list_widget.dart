import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/event_model.dart';

class EventListWidget extends StatefulWidget {
  final VoidCallback? onUpdate;
  final Function(ScheduledEvent)? onEdit;
  const EventListWidget({Key? key, this.onUpdate, this.onEdit}) : super(key: key);

  @override
  _EventListWidgetState createState() => _EventListWidgetState();
}

class _EventListWidgetState extends State<EventListWidget> {
  final ApiService _api = ApiService();
  bool _isRefreshing = false;

  void _refresh() {
    setState(() => _isRefreshing = true);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isRefreshing = false);
    });
  }

  String _formatRecurrence(String rule) {
    if (rule.contains('DAILY')) {
      final intervalMatch = RegExp(r'INTERVAL=(\d+)').firstMatch(rule);
      if (intervalMatch != null && intervalMatch.group(1) != '1') return "Every ${intervalMatch.group(1)} days";
      return "Daily";
    }
    if (rule.contains('WEEKLY')) {
      final daysMatch = RegExp(r'BYDAY=([^;]+)').firstMatch(rule);
      final intervalMatch = RegExp(r'INTERVAL=(\d+)').firstMatch(rule);
      String prefix = "Weekly";
      if (intervalMatch != null && intervalMatch.group(1) != '1') prefix = "Every ${intervalMatch.group(1)} weeks";
      if (daysMatch != null) return "$prefix on ${daysMatch.group(1)}";
      return prefix;
    }
    if (rule.contains('MONTHLY') || rule.contains('YEARLY')) {
      final type = rule.contains('MONTHLY') ? "Monthly" : "Yearly";
      final posMatch = RegExp(r'BYSETPOS=([-]?\d+)').firstMatch(rule);
      final daysMatch = RegExp(r'BYDAY=([^;]+)').firstMatch(rule);
      
      if (posMatch != null) {
        final pos = posMatch.group(1);
        final posText = pos == '1' ? "First" : pos == '2' ? "Second" : pos == '3' ? "Third" : pos == '4' ? "Fourth" : pos == '-1' ? "Last" : pos;
        final days = daysMatch != null ? daysMatch.group(1) : "occurrence";
        return "$posText $days of the ${type == 'Monthly' ? 'month' : 'year'}";
      }
      return type;
    }
    return "Recurring";
  }

  void _deleteEvent(String id) async {
    await _api.deleteEvent(id);
    if (widget.onUpdate != null) widget.onUpdate!();
    _refresh();
  }

  void _showDetailDialog(ScheduledEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(event.icon, color: event.color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(event.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow(Icons.access_time, "Time", "${DateFormat('EEEE, MMM d').format(event.startTime)}\n${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}"),
            if (event.location.isNotEmpty) _detailRow(Icons.location_on, "Location", event.location),
            if (event.description.isNotEmpty) _detailRow(Icons.description, "Description", event.description),
            if (event.recurrenceRule != null) _detailRow(Icons.repeat, "Frequency", _formatRecurrence(event.recurrenceRule!)),
            _detailRow(Icons.public, "Timezone", event.timezone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onEdit != null) widget.onEdit!(event);
            }, 
            child: const Text("Edit"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.indigo),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isRefreshing) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));

    return FutureBuilder<List<ScheduledEvent>>(
      future: _api.getEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.indigo));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text("No upcoming events yet.", style: TextStyle(color: Colors.grey[600], fontSize: 18)),
              ],
            ),
          );
        }

        final events = snapshot.data!;
        events.sort((a, b) => a.startTime.compareTo(b.startTime));

        return ListView.builder(
          shrinkWrap: true, // Crucial when inside SingleChildScrollView
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];

            return Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    // Tappable info area
                    Expanded(
                      child: InkWell(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                        onTap: () => _showDetailDialog(event),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: event.color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(event.icon, color: event.color, size: 24),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.subject,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
                                    ),
                                    if (event.description.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        event.description,
                                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormat('MMM d, h:mm a').format(event.startTime),
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Actions area
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.indigo, size: 22),
                            onPressed: () {
                              if (widget.onEdit != null) widget.onEdit!(event);
                              _refresh();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                            onPressed: () => _deleteEvent(event.id),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}


