import 'package:flutter/material.dart' hide SelectionDetails;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/event_model.dart';
import '../services/google_calendar_service.dart';
import '../services/notification_service.dart';

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
    if (!mounted) return;
    // Use addPostFrameCallback if called during initState/build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isLoading = true);
    });
    try {
      final events = await _api.getEvents();
      if (mounted) {
        setState(() => _events = events);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading events: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                  event?.recurrenceRule?.contains('MONTHLY') == true ? 'MONTHLY' :
                  event?.recurrenceRule?.contains('YEARLY') == true ? 'YEARLY' : null;
    
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
    DateTime? untilDate;

    // Parse UNTIL from rule
    if (event?.recurrenceRule?.contains('UNTIL=') == true) {
      final match = RegExp(r'UNTIL=(\d{4})(\d{2})(\d{2})').firstMatch(event!.recurrenceRule!);
      if (match != null) {
        untilDate = DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }
    }

    List<int> selectedMonthDays = [];
    if (event?.recurrenceRule?.contains('BYMONTHDAY=') == true) {
      final match = RegExp(r'BYMONTHDAY=([^;]+)').firstMatch(event!.recurrenceRule!);
      if (match != null) {
        selectedMonthDays = match.group(1)!.split(',').map(int.parse).toList();
      }
    } else if (freq == 'MONTHLY' && bySetPos == null) {
      // Default to the start date's day if it's a simple monthly recurrence
      selectedMonthDays = [startTime.day];
    }

    Color selectedColor = event?.color ?? Colors.indigo;
    bool hasReminder = event?.hasReminder ?? false;
    int reminderMinutes = event?.reminderMinutesBefore ?? 15;
    String selectedTimezone = event?.timezone ?? 'UTC';

    // --- Validation state ---
    String? titleError;
    String? timeError;
    String? recurrenceError;

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
                // --- Error banner ---
                if (timeError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(timeError!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                      ],
                    ),
                  ),
                if (recurrenceError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(recurrenceError!, style: const TextStyle(color: Colors.orange, fontSize: 13))),
                      ],
                    ),
                  ),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: "Event Title *",
                    prefixIcon: const Icon(Icons.title),
                    errorText: titleError,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    if (titleError != null) setModalState(() => titleError = null);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Description",
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: "Location",
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text("Start Time"),
                        subtitle: Text(DateFormat('MMM d, h:mm a').format(startTime)),
                        leading: const Icon(Icons.access_time, color: Colors.indigo),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: startTime,
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (pickedDate == null) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(startTime),
                          );
                          if (time != null) {
                            setModalState(() {
                              startTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, time.hour, time.minute);
                              if (endTime.isBefore(startTime)) {
                                endTime = startTime.add(const Duration(hours: 1));
                              }
                              timeError = null;
                            });
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text("End Time"),
                        subtitle: Text(DateFormat('MMM d, h:mm a').format(endTime)),
                        leading: const Icon(Icons.access_time_filled, color: Colors.indigo),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: endTime,
                            firstDate: startTime,
                            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                          );
                          if (pickedDate == null) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(endTime),
                          );
                          if (time != null) {
                            setModalState(() {
                              endTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, time.hour, time.minute);
                              timeError = null;
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
                    DropdownMenuItem(child: Text("None (Single Event)"), value: null),
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
                        value: bySetPos == null ? null : (bySetPos != null ? 1 : null), // Use 1 as a proxy for 'any relative'
                        decoration: const InputDecoration(labelText: "Frequency Mode", prefixIcon: Icon(Icons.format_list_numbered)),
                        items: const [
                          DropdownMenuItem(child: Text("Specific Date(s)"), value: null),
                          DropdownMenuItem(child: Text("Relative (e.g. First Friday)"), value: 1),
                        ],
                        onChanged: (val) => setModalState(() {
                          if (val == 1) {
                            bySetPos = 1; // Default to first if switching to relative
                            if (selectedDays.isEmpty) {
                              final day = DateFormat('EE').format(startTime).substring(0, 2).toUpperCase();
                              selectedDays = [day];
                            }
                          } else {
                            bySetPos = null;
                          }
                        }),
                      ),
                      if (bySetPos == null && freq == 'MONTHLY') ...[
                        const SizedBox(height: 10),
                        const Text("Select Days of Month:"),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: List.generate(31, (index) {
                            final day = index + 1;
                            return ChoiceChip(
                              label: Text(day.toString(), style: const TextStyle(fontSize: 10)),
                              selected: selectedMonthDays.contains(day),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedMonthDays.add(day);
                                  } else {
                                    if (selectedMonthDays.length > 1) selectedMonthDays.remove(day);
                                  }
                                  selectedMonthDays.sort();
                                });
                              },
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            );
                          }),
                        ),
                      ],
                      if (bySetPos != null) ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          value: bySetPos,
                          decoration: const InputDecoration(labelText: "Occurrence", prefixIcon: Icon(Icons.repeat_one)),
                          items: const [
                            DropdownMenuItem(child: Text("First occurrence"), value: 1),
                            DropdownMenuItem(child: Text("Second occurrence"), value: 2),
                            DropdownMenuItem(child: Text("Third occurrence"), value: 3),
                            DropdownMenuItem(child: Text("Fourth occurrence"), value: 4),
                            DropdownMenuItem(child: Text("Last occurrence"), value: -1),
                          ],
                          onChanged: (val) => setModalState(() => bySetPos = val),
                        ),
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
                      ],
                    ],
                    const SizedBox(height: 15),
                    ListTile(
                      title: const Text("End Recurrence", style: TextStyle(fontSize: 14)),
                      subtitle: Text(untilDate == null ? "Never" : DateFormat('MMM d, yyyy').format(untilDate!)),
                      trailing: untilDate != null ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setModalState(() => untilDate = null),
                      ) : null,
                      leading: const Icon(Icons.event_busy, color: Colors.grey),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: untilDate ?? startTime.add(const Duration(days: 30)),
                          firstDate: startTime,
                          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                        );
                        if (picked != null) setModalState(() => untilDate = picked);
                      },
                    ),
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
                if (freq != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.indigo),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Pattern: Repeats ${interval > 1 ? 'every $interval ' : ''}${freq?.toLowerCase() ?? ''}${freq == 'WEEKLY' && selectedDays.isNotEmpty ? ' on ${selectedDays.join(", ")}' : freq == 'MONTHLY' && bySetPos != null ? ' on the ${bySetPos == 1 ? '1st' : bySetPos == 2 ? '2nd' : bySetPos == 3 ? '3rd' : bySetPos == 4 ? '4th' : 'last'} ${selectedDays.join(", ")}' : freq == 'MONTHLY' && bySetPos == null ? ' on day(s) ${selectedMonthDays.join(", ")}' : ''}",
                            style: const TextStyle(fontSize: 12, color: Colors.indigo, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                            final String? result = await showDialog<String>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Event?"),
                                content: Text(event.recurrenceRule != null 
                                  ? "Do you want to delete only this instance or the entire series?"
                                  : "This will permanently remove this event."),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Cancel")),
                                  if (event.recurrenceRule != null)
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, 'instance'), 
                                      child: const Text("Only this instance")
                                    ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, 'all'), 
                                    child: Text(event.recurrenceRule != null ? "Entire series" : "Delete", style: const TextStyle(color: Colors.red))
                                  ),
                                ],
                              ),
                            );

                            if (result == null) return;

                            try {
                              if (result == 'all') {
                                await _api.deleteEvent(event.id);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Series deleted")));
                                }
                              } else {
                                // Add current startTime to exceptions
                                final List<DateTime> updatedExceptions = List<DateTime>.from(event.recurrenceExceptionDates ?? []);
                                updatedExceptions.add(event.startTime);
                                final updatedEvent = ScheduledEvent(
                                  id: event.id,
                                  subject: event.subject,
                                  startTime: event.startTime,
                                  endTime: event.endTime,
                                  location: event.location,
                                  description: event.description,
                                  recurrenceRule: event.recurrenceRule,
                                  color: event.color,
                                  hasReminder: event.hasReminder,
                                  reminderMinutesBefore: event.reminderMinutesBefore,
                                  timezone: event.timezone,
                                  recurrenceExceptionDates: updatedExceptions,
                                );
                                await _api.updateEvent(updatedEvent);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Instance removed")));
                                }
                              }
                              await _loadEvents();
                              if (widget.onEventUpdated != null) widget.onEventUpdated!();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete error: $e")));
                              }
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
                          // --- Full Validation ---
                          bool isValid = true;

                          if (titleController.text.trim().isEmpty) {
                            setModalState(() => titleError = 'Event title is required.');
                            isValid = false;
                          } else if (titleController.text.trim().length < 2) {
                            setModalState(() => titleError = 'Title must be at least 2 characters.');
                            isValid = false;
                          } else if (titleController.text.trim().length > 100) {
                            setModalState(() => titleError = 'Title must be under 100 characters.');
                            isValid = false;
                          } else if (!RegExp(r'[a-zA-Z0-9]').hasMatch(titleController.text)) {
                            setModalState(() => titleError = 'Title must contain at least one letter or number.');
                            isValid = false;
                          } else {
                            setModalState(() => titleError = null);
                          }

                          if (!endTime.isAfter(startTime)) {
                            setModalState(() => timeError = 'End time must be after start time.');
                            isValid = false;
                          } else if (endTime.difference(startTime).inMinutes < 5) {
                            setModalState(() => timeError = 'Event must be at least 5 minutes long.');
                            isValid = false;
                          } else {
                            setModalState(() => timeError = null);
                          }

                          // --- Recurrence Validation ---
                          if (freq != null) {
                            if (untilDate != null && !untilDate!.isAfter(startTime)) {
                              setModalState(() => recurrenceError = "End date must be after start date.");
                              isValid = false;
                            } else if (freq == 'MONTHLY' && bySetPos == null && selectedMonthDays.isEmpty) {
                              setModalState(() => recurrenceError = "Please select at least one day of the month.");
                              isValid = false;
                            } else {
                              setModalState(() => recurrenceError = null);
                            }
                          } else {
                            setModalState(() => recurrenceError = null);
                          }

                          if (!isValid) return;

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
                            } else if (freq == 'MONTHLY') {
                              if (bySetPos == null) {
                                // Important: startTime.day MUST be in the BYMONTHDAY list for Syncfusion to expand correctly.
                                // If the current startTime.day isn't there, we move the startTime to the first selected day.
                                final int firstDay = selectedMonthDays.isEmpty ? startTime.day : selectedMonthDays.first;
                                if (startTime.day != firstDay) {
                                  startTime = DateTime(startTime.year, startTime.month, firstDay, startTime.hour, startTime.minute);
                                  if (endTime.isBefore(startTime)) {
                                    endTime = startTime.add(const Duration(hours: 1));
                                  }
                                }
                                rule += ";BYMONTHDAY=${selectedMonthDays.isEmpty ? startTime.day : selectedMonthDays.join(',')}";
                              } else {
                                if (selectedDays.isEmpty) {
                                  final day = DateFormat('EE').format(startTime).substring(0, 2).toUpperCase();
                                  rule += ";BYDAY=$day;BYSETPOS=$bySetPos";
                                } else {
                                  rule += ";BYDAY=${selectedDays.join(',')};BYSETPOS=$bySetPos";
                                }
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

                            if (untilDate != null) {
                              final untilStr = DateFormat('yyyyMMdd').format(untilDate!);
                              rule += ";UNTIL=$untilStr";
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

                            // Schedule Notification if reminder is set
                            if (updatedEvent.hasReminder) {
                              final DateTime reminderTime = updatedEvent.startTime.subtract(
                                Duration(minutes: updatedEvent.reminderMinutesBefore ?? 15),
                              );
                              if (reminderTime.isAfter(DateTime.now())) {
                                await NotificationService().scheduleReminder(
                                  updatedEvent.subject,
                                  reminderTime,
                                  body: "Starting soon at ${DateFormat('h:mm a').format(updatedEvent.startTime)}",
                                );
                              }
                            }

                            Navigator.pop(context);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(event == null ? "Event created successfully!" : "Event updated successfully!")),
                              );
                            }
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
  CalendarView _currentView = CalendarView.month;

  Widget _viewButton(String label, CalendarView view) {
    final bool isSelected = _currentView == view;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.indigo, fontSize: 12)),
        selected: isSelected,
        selectedColor: Colors.indigo,
        backgroundColor: Colors.indigo.withOpacity(0.05),
        onSelected: (selected) {
          if (selected) setState(() => _currentView = view);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Custom Header / View Switcher ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _calendarController.displayDate = DateTime.now()),
                icon: const Icon(Icons.today, size: 20),
                label: const Text("Today"),
                style: TextButton.styleFrom(foregroundColor: Colors.indigo),
              ),
              const Spacer(),
              _viewButton("Month", CalendarView.month),
              _viewButton("Week", CalendarView.week),
              _viewButton("Day", CalendarView.day),
            ],
          ),
        ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SfCalendar(
                controller: _calendarController,
                view: _currentView,
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
                  // Use post frame callback to avoid '!_dirty' assertion error 
                  // during build-phase selection changes
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() {});
                  });
                },
                monthCellBuilder: (context, details) {
            final bool isSelected = details.date == _calendarController.selectedDate;
            final DateTime now = DateTime.now();
            final bool isToday = details.date.year == now.year && 
                                details.date.month == now.month && 
                                details.date.day == now.day;

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
                           child: Container(color: color.withOpacity(0.4)),
                         )).toList(),
                       ),
                     ),
                   
                   // Today Highlight (Circle background)
                   if (isToday)
                     Center(
                       child: Container(
                         width: 32,
                         height: 32,
                         decoration: BoxDecoration(
                           color: Colors.indigo.withOpacity(0.1),
                           shape: BoxShape.circle,
                           border: Border.all(color: Colors.indigo.withOpacity(0.5), width: 1),
                         ),
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
                         fontWeight: (isSelected || isToday) ? FontWeight.bold : (dayColors.isNotEmpty ? FontWeight.w600 : FontWeight.normal),
                         color: isCurrentMonth 
                            ? (isToday ? Colors.indigo : (isSelected ? Colors.indigo : (dayColors.isNotEmpty ? Colors.black87 : Colors.black54))) 
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
        ),
      ),
    ],
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

  @override
  List<DateTime>? getRecurrenceExceptionDates(int index) {
     return appointments![index].recurrenceExceptionDates;
  }
}
