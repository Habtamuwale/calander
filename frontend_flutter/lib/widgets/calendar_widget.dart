import 'package:flutter/material.dart' hide SelectionDetails;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/event_model.dart';
import '../services/google_calendar_service.dart';

class CalendarWidget extends StatefulWidget {
  final Function? onEventUpdated;
  const CalendarWidget({Key? key, this.onEventUpdated}) : super(key: key);

  @override
  CalendarWidgetState createState() => CalendarWidgetState();
}

class CalendarWidgetState extends State<CalendarWidget> {
  final ApiService _api = ApiService();
  final GoogleCalendarService _googleSync = GoogleCalendarService();
  List<ScheduledEvent> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _api.getEvents();
      setState(() => _events = events);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading events: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void refresh() => _loadEvents();
  void addNewEvent() => showEditDialog();

  void _onTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.calendarCell) {
      showEditDialog(date: details.date!);
    } else if (details.targetElement == CalendarElement.appointment || 
               details.targetElement == CalendarElement.agenda) {
      if (details.appointments != null && details.appointments!.isNotEmpty) {
        final dynamic app = details.appointments![0];
        ScheduledEvent? event;
        if (app is ScheduledEvent) {
          event = app;
        } else {
          // If Syncfusion wrapped it in an Appointment object, find it by ID
          final String id = app.id?.toString() ?? '';
          event = _events.firstWhere((e) => e.id == id, orElse: () => _events[0]);
        }
        showEditDialog(event: event);
      }
    }
  }

  void showEditDialog({DateTime? date, ScheduledEvent? event}) {
    final titleController = TextEditingController(text: event?.subject ?? '');
    final locationController = TextEditingController(text: event?.location ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');
    
    // Recurrence state
    String? freq = event?.recurrenceRule?.contains('DAILY') == true ? 'DAILY' :
                  event?.recurrenceRule?.contains('WEEKLY') == true ? 'WEEKLY' :
                  event?.recurrenceRule?.contains('MONTHLY') == true ? 'MONTHLY' : null;
    
    int interval = 1;
    if (event?.recurrenceRule?.contains('INTERVAL=') == true) {
      final match = RegExp(r'INTERVAL=(\d+)').firstMatch(event!.recurrenceRule!);
      if (match != null) interval = int.parse(match.group(1)!);
    }

    List<String> selectedDays = [];
    if (event?.recurrenceRule?.contains('BYDAY=') == true) {
      final match = RegExp(r'BYDAY=([^;]+)').firstMatch(event!.recurrenceRule!);
      if (match != null) selectedDays = match.group(1)!.split(',');
    }

    int? bySetPos;
    if (event?.recurrenceRule?.contains('BYSETPOS=') == true) {
       final match = RegExp(r'BYSETPOS=([-]?\d+)').firstMatch(event!.recurrenceRule!);
       if (match != null) bySetPos = int.parse(match.group(1)!);
    }

    DateTime startTime = event?.startTime ?? date ?? DateTime.now();
    DateTime endTime = event?.endTime ?? startTime.add(const Duration(hours: 1));

    Color selectedColor = event?.color ?? Colors.indigo;
    bool hasReminder = event?.hasReminder ?? false;
    int reminderMinutes = event?.reminderMinutesBefore ?? 15;
    String selectedTimezone = event?.timezone ?? 'UTC';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event == null ? "New Event" : "Edit Event",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Event Title", prefixIcon: Icon(Icons.title)),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Description", prefixIcon: Icon(Icons.description)),
                  maxLines: 2,
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: "Location", prefixIcon: Icon(Icons.location_on)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text("Start Time"),
                        subtitle: Text(DateFormat('h:mm a').format(startTime)),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(startTime),
                          );
                          if (time != null) {
                            setModalState(() {
                              startTime = DateTime(startTime.year, startTime.month, startTime.day, time.hour, time.minute);
                              if (endTime.isBefore(startTime)) {
                                endTime = startTime.add(const Duration(hours: 1));
                              }
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text("End Time"),
                        subtitle: Text(DateFormat('h:mm a').format(endTime)),
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(endTime),
                          );
                          if (time != null) {
                            setModalState(() {
                              endTime = DateTime(endTime.year, endTime.month, endTime.day, time.hour, time.minute);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text("Recurrence Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                DropdownButtonFormField<String>(
                  value: freq,
                  decoration: const InputDecoration(labelText: "Frequency", prefixIcon: Icon(Icons.repeat)),
                  items: const [
                    DropdownMenuItem(child: Text("None"), value: null),
                    DropdownMenuItem(child: Text("Daily"), value: "DAILY"),
                    DropdownMenuItem(child: Text("Weekly"), value: "WEEKLY"),
                    DropdownMenuItem(child: Text("Monthly"), value: "MONTHLY"),
                    DropdownMenuItem(child: Text("Yearly"), value: "YEARLY"),
                  ],
                  onChanged: (val) => setModalState(() => freq = val),
                ),
                if (freq != null) ...[
                  Row(
                    children: [
                      const Text("Every "),
                      SizedBox(
                        width: 50,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true),
                          onChanged: (v) => interval = int.tryParse(v) ?? 1,
                          controller: TextEditingController(text: interval.toString()),
                        ),
                      ),
                      Text(freq == 'DAILY' ? " day(s)" : freq == 'WEEKLY' ? " week(s)" : freq == 'MONTHLY' ? " month(s)" : " year(s)"),
                    ],
                  ),
                  if (freq == 'WEEKLY') ...[
                    const SizedBox(height: 10),
                    const Text("On days:"),
                    Wrap(
                      spacing: 8,
                      children: ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'].map((day) => FilterChip(
                        label: Text(day),
                        selected: selectedDays.contains(day),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) selectedDays.add(day);
                            else selectedDays.remove(day);
                          });
                        },
                      )).toList(),
                    ),
                  ],
                  if (freq == 'MONTHLY' || freq == 'YEARLY') ...[
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: bySetPos,
                      decoration: const InputDecoration(labelText: "Position", prefixIcon: Icon(Icons.format_list_numbered)),
                      items: const [
                        DropdownMenuItem(child: Text("Same date each cycle"), value: null),
                        DropdownMenuItem(child: Text("First occurrence"), value: 1),
                        DropdownMenuItem(child: Text("Second occurrence"), value: 2),
                        DropdownMenuItem(child: Text("Third occurrence"), value: 3),
                        DropdownMenuItem(child: Text("Fourth occurrence"), value: 4),
                        DropdownMenuItem(child: Text("Last occurrence"), value: -1),
                      ],
                      onChanged: (val) => setModalState(() => bySetPos = val),
                    ),
                    if (bySetPos != null) ...[
                       const SizedBox(height: 10),
                       const Text("Of which days:"),
                       Wrap(
                          spacing: 4,
                          children: ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'].map((day) => FilterChip(
                            label: Text(day, style: const TextStyle(fontSize: 10)),
                            selected: selectedDays.contains(day),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) selectedDays.add(day);
                                else selectedDays.remove(day);
                              });
                            },
                          )).toList(),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () => setModalState(() => selectedDays = ['MO', 'TU', 'WE', 'TH', 'FR']),
                          child: const Text("Select All Weekdays", style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ],
                ],
                const SizedBox(height: 20),
                SwitchListTile(
                  title: const Text("Set Reminder", style: TextStyle(fontSize: 14)),
                  secondary: Icon(Icons.notifications_active, color: hasReminder ? Colors.orange : Colors.grey),
                  value: hasReminder,
                  onChanged: (val) => setModalState(() => hasReminder = val),
                ),
                if (hasReminder)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Row(
                      children: [
                        const Text("Remind me ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        DropdownButton<int>(
                          value: reminderMinutes,
                          onChanged: (val) => setModalState(() => reminderMinutes = val!),
                          items: [5, 10, 15, 30, 60].map((m) => DropdownMenuItem(child: Text("$m mins"), value: m)).toList(),
                        ),
                        const Text(" before", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                const SizedBox(height: 15),
                const Text("Pick a Color:"),
                Row(
                  children: [Colors.indigo, Colors.red, Colors.green, Colors.orange, Colors.pink].map((c) => 
                    GestureDetector(
                      onTap: () => setModalState(() => selectedColor = c),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: c, 
                          shape: BoxShape.circle,
                          border: selectedColor == c ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                      ),
                    )
                  ).toList(),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    if (event != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            try {
                              await _api.deleteEvent(event.id);
                              Navigator.pop(context);
                              await _loadEvents();
                              if (widget.onEventUpdated != null) widget.onEventUpdated!();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete error: $e")));
                            }
                          },
                          child: const Text("Delete", style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    if (event != null) const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Title is required")));
                            return;
                          }

                          String? rule;
                          if (freq != null) {
                            rule = "FREQ=$freq";
                            if (interval > 1) rule += ";INTERVAL=$interval";
                            
                            if (freq == 'WEEKLY') {
                              if (selectedDays.isEmpty) {
                                final day = DateFormat('EE').format(startTime).substring(0, 2).toUpperCase();
                                rule += ";BYDAY=$day";
                              } else {
                                rule += ";BYDAY=${selectedDays.join(',')}";
                              }
                            } else if (freq == 'MONTHLY' && bySetPos != null) {
                              if (selectedDays.isEmpty) {
                                final day = DateFormat('EE').format(startTime).substring(0, 2).toUpperCase();
                                rule += ";BYDAY=$day;BYSETPOS=$bySetPos";
                              } else {
                                rule += ";BYDAY=${selectedDays.join(',')};BYSETPOS=$bySetPos";
                              }
                            } else if (freq == 'YEARLY' && bySetPos != null) {
                               // Syncfusion requires BYMONTH for yearly relative rules
                               rule += ";BYMONTH=${startTime.month}"; 
                               if (selectedDays.isEmpty) {
                                 final day = DateFormat('EE').format(startTime).substring(0, 2).toUpperCase();
                                 rule += ";BYDAY=$day;BYSETPOS=$bySetPos";
                               } else {
                                 rule += ";BYDAY=${selectedDays.join(',')};BYSETPOS=$bySetPos";
                               }
                            }
                          }

                          final updatedEvent = ScheduledEvent(
                            id: event?.id ?? '',
                            subject: titleController.text,
                            startTime: startTime,
                            endTime: endTime,
                            location: locationController.text,
                            description: descriptionController.text,
                            recurrenceRule: rule,
                            color: selectedColor,
                            hasReminder: hasReminder,
                            reminderMinutesBefore: reminderMinutes,
                            timezone: selectedTimezone,
                          );
                          
                          try {
                            if (event == null) {
                              await _api.createEvent(updatedEvent);
                            } else {
                              await _api.updateEvent(updatedEvent);
                            }
                            Navigator.pop(context);
                            await _loadEvents();
                            if (widget.onEventUpdated != null) widget.onEventUpdated!();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                          }
                        },
                        child: const Text("Save Event"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final CalendarController _calendarController = CalendarController();

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const SizedBox(height: 500, child: Center(child: CircularProgressIndicator()))
      : SfCalendar(
          controller: _calendarController,
          view: CalendarView.month,
          showNavigationArrow: true,
          dataSource: EventDataSource(_events),
          monthViewSettings: const MonthViewSettings(
            showAgenda: true,
            agendaViewHeight: 200,
            showTrailingAndLeadingDates: false,
            agendaStyle: AgendaStyle(
              backgroundColor: Colors.white,
              appointmentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
              dateTextStyle: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
            ),
          ),
          onSelectionChanged: (details) {
            setState(() {}); // Rebuild to update cell shading
          },
          monthCellBuilder: (context, details) {
            final bool isSelected = details.date == _calendarController.selectedDate;
            final DateTime currentMonthDate = _calendarController.displayDate ?? DateTime.now();
            final bool isCurrentMonth = details.date.month == currentMonthDate.month && 
                                       details.date.year == currentMonthDate.year;

            // Get colors of all events on this day
            final List<Color> dayColors = details.appointments.map((e) {
              if (e is ScheduledEvent) return e.color;
              if (e is Appointment) return e.color;
              return Colors.indigo;
            }).toList().cast<Color>();

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.1), width: 0.5),
              ),
              child: Stack(
                children: [
                   // Background colored stripes for each event (Ratio display)
                   if (dayColors.isNotEmpty)
                     Positioned.fill(
                       child: Column(
                         children: dayColors.map((color) => Expanded(
                           child: Container(color: color.withOpacity(0.2)),
                         )).toList(),
                       ),
                     ),
                   
                   // Selection highlight overlay
                   if (isSelected)
                     Positioned.fill(
                       child: Container(
                         decoration: BoxDecoration(
                           border: Border.all(color: Colors.indigo, width: 2),
                           color: Colors.indigo.withOpacity(0.1),
                         ),
                       ),
                     ),

                   // Date number
                   Center(
                     child: Text(
                       details.date.day.toString(),
                       style: TextStyle(
                         fontWeight: isSelected ? FontWeight.bold : (dayColors.isNotEmpty ? FontWeight.w600 : FontWeight.normal),
                         color: isCurrentMonth 
                            ? (isSelected ? Colors.indigo : (dayColors.isNotEmpty ? Colors.black87 : Colors.black54)) 
                            : Colors.transparent,
                       ),
                     ),
                   ),
                ],
              ),
            );
          },
          headerStyle: const CalendarHeaderStyle(
            textAlign: TextAlign.center,
            textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
          ),
          allowDragAndDrop: true,
          onDragEnd: (dynamic details) {
            if (details.appointment != null) {
              final ScheduledEvent event = details.appointment as ScheduledEvent;
              _api.updateEvent(event);
            }
          },
          onTap: _onTap,
        );
  }
}

class EventDataSource extends CalendarDataSource {
  EventDataSource(List<ScheduledEvent> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) => appointments![index].startTime;

  @override
  DateTime getEndTime(int index) => appointments![index].endTime;

  @override
  String getSubject(int index) => appointments![index].subject;

  @override
  Color getColor(int index) => appointments![index].color;

  @override
  String? getRecurrenceRule(int index) {
     try {
       final rule = appointments![index].recurrenceRule;
       if (rule == null) return null;
       
       // CRITICAL FIX: Ensure rules have mandatory parameters to prevent Syncfusion crash
       if (rule.contains('WEEKLY') && !rule.contains('BYDAY=')) {
          final day = DateFormat('EE').format(appointments![index].startTime).substring(0, 2).toUpperCase();
          return "$rule;BYDAY=$day";
       }

       // Yearly relative rules MUST have BYMONTH in Syncfusion
       if (rule.contains('YEARLY') && rule.contains('BYSETPOS=') && !rule.contains('BYMONTH=')) {
          return "$rule;BYMONTH=${appointments![index].startTime.month}";
       }

       return rule;
     } catch (e) {
       // Catch all formatting exceptions to prevent app-level crash
       return null; 
     }
  }
}
