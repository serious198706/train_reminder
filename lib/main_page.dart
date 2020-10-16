import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:train_reminder/db_helper.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  CalendarController _calendarController;
  Map<DateTime, List> _events;
  DateTime _selectedDateTime;
  List _selectedEvents;
  bool _hasEvent = false;
  DBHelper _db;
  IconData _icon = Icons.add;

  @override
  void initState() {
    super.initState();

    _calendarController = CalendarController();

    final _selectedDay = DateTime.now();
    _events = Map();
    _selectedEvents = _events[_selectedDay] ?? [];
    _hasEvent = _selectedEvents.isNotEmpty;
    _loadStored();
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      appBar: AppBar(
        title: Text('TrainReminder'),
        backgroundColor: Color(0xFF56A902),
        actions: [
          GestureDetector(
            child: Text('TODAY'),
            onTap: () {
              _calendarController.setSelectedDay(DateTime.now());
            },
          )
        ],
      ),
      body: Column(children: [
        _buildTableCalendarWithBuilders(),
        SizedBox(height: 8.0),
        Container(color: Colors.grey.shade100, height: 8.0),
        Expanded(child: _buildEventList()),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _hasEvent ? Colors.red : Colors.green,
        onPressed: _onAction,
        child: AnimatedSwitcher(
          transitionBuilder: (_, __) {
            return ScaleTransition(child: _, scale: __);
          },
          duration: Duration(milliseconds: 300),
          child: Icon(_icon, key: ValueKey(_icon)),
        ),
      ),
    );
  }

  Widget _buildTableCalendarWithBuilders() {
    return TableCalendar(
      calendarController: _calendarController,
      events: _events,
      initialCalendarFormat: CalendarFormat.month,
      formatAnimation: FormatAnimation.slide,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      availableGestures: AvailableGestures.all,
      availableCalendarFormats: const {
        CalendarFormat.month: '',
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        weekendStyle: TextStyle().copyWith(color: Colors.blue[800]),
        holidayStyle: TextStyle().copyWith(color: Colors.blue[800]),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekendStyle: TextStyle().copyWith(color: Colors.blue[600]),
      ),
      headerStyle: HeaderStyle(
        centerHeaderTitle: true,
        formatButtonVisible: false,
      ),
      builders: CalendarBuilders(
        todayDayBuilder: (_, date, __) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
                color: Color(0x8875D701),
                border: Border.all(color: Colors.green, width: 1.0),
                borderRadius: BorderRadius.all(Radius.circular(30.0))),
            width: 100,
            height: 100,
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: TextStyle().copyWith(fontSize: 16.0),
            ),
          );
        },
        selectedDayBuilder: (_, date, __) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
                color: Color(0xFF3B4E32),
                borderRadius: BorderRadius.all(Radius.circular(30.0))),
            width: 100,
            height: 100,
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: TextStyle().copyWith(fontSize: 16.0, color: Colors.white),
            ),
          );
        },
        markersBuilder: (context, date, events, holidays) {
          final children = <Widget>[];

          if (events.isNotEmpty) {
            children.add(
              Positioned(
                right: 1,
                bottom: 1,
                child: _buildEventsMarker(date, events),
              ),
            );
          }

          return children;
        },
      ),
      onDaySelected: _onDaySelected,
    );
  }

  Widget _buildEventList() {
    if (_selectedEvents == null || _selectedEvents.isEmpty) {
      return Container();
    }

    Info info = _selectedEvents[0];
    if (info == null) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Text('Ticket Info',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey)),
        ),
        ListTile(
          leading: Icon(Icons.timer),
          title: Text('Datetime', style: TextStyle(fontSize: 18)),
          trailing: Text(DateFormat('yyyy-MM-dd HH:mm').format(info.datetime),
              style: TextStyle(color: Colors.grey, fontSize: 18)),
        ),
        ListTile(
          leading: Icon(Icons.train),
          title: Text('Carriage', style: TextStyle(fontSize: 18)),
          trailing: Text('No.' + info.carriage,
              style: TextStyle(color: Colors.grey, fontSize: 18)),
        ),
        ListTile(
          leading: Icon(Icons.airline_seat_flat),
          title: Text('Seat', style: TextStyle(fontSize: 18)),
          trailing: Text(info.seat.toUpperCase(),
              style: TextStyle(color: Colors.grey, fontSize: 18)),
        ),
      ],
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return Container(
      padding: EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.all(Radius.circular(39)),
      ),
      child: Icon(
        Icons.train,
        color: Colors.green,
        size: 16.0,
      ),
    );
  }

  void _onDaySelected(DateTime dateTime, List events, List holidays) {
    setState(() {
      _selectedDateTime = dateTime;
      _selectedEvents = events;
      _hasEvent = _selectedEvents.isNotEmpty;
      _icon = _hasEvent ? Icons.remove : Icons.add;
    });
  }

  void _onAction() {
    if (_hasEvent) {
      _removeEvent();
    } else {
      _addEvent();
    }
  }

  void _addEvent() async {
    TimeOfDay time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());

    if (time == null) {
      return;
    }

    Info result = await _showDetailDialog(time);

    if (result == null) {
      return;
    }

    int id = await _db.insert(result);
    result.id = id;

    setState(() {
      _events[_selectedDateTime] = [result];
      _hasEvent = true;
      _icon = Icons.remove;
      _selectedEvents = _events[_selectedDateTime];
    });
  }

  void _modifyEvent({Info info}) async {
    TimeOfDay time = await showTimePicker(
        context: context,
        initialTime: info != null
            ? TimeOfDay(hour: info.datetime.hour, minute: info.datetime.minute)
            : TimeOfDay.now());

    if (time == null) {
      return;
    }

    Info result = await _showDetailDialog(time, info: info);

    if (result == null) {
      return;
    }

    await _db.update(result);

    setState(() {
      _events[_selectedDateTime] = [result];
      _hasEvent = true;
      _icon = Icons.remove;
      _selectedEvents = _events[_selectedDateTime];
    });
  }

  void _removeEvent() async {
    Info info = _events[_selectedDateTime][0];
    await _db.delete(info.id);

    setState(() {
      _events[_selectedDateTime] = [];
      _hasEvent = false;
      _icon = Icons.add;
      _selectedEvents = _events[_selectedDateTime];
    });
  }

  Future<Info> _showDetailDialog(TimeOfDay time, {Info info}) async {
    return await showDialog(
      context: context,
      builder: (_) {
        final _formKey = GlobalKey<FormState>();
        final _carriageController =
            TextEditingController(text: info != null ? info.carriage : '');
        final _seatController =
            TextEditingController(text: info != null ? info.seat : '');
        return AlertDialog(
          title: Text('Carriage And Seat'),
          content: Form(
            key: _formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _carriageController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9]'))
                    ],
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Carriage can not be empty.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                        labelText: 'Carriage',
                        hintText: 'Input carriage. Range(1-16)'),
                  ),
                  TextFormField(
                    controller: _seatController,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Seat can not be empty';
                      } else if (!RegExp('[0-9][A-Fa-f]').hasMatch(value)) {
                        return 'Malformed seat.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                        labelText: 'Seat', hintText: 'Input seat. Exp: 8A/12D'),
                  ),
                ]),
          ),
          actions: [
            FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                textColor: Colors.grey,
                child: Text('CANCEL')),
            FlatButton(
                onPressed: () {
                  if (_formKey.currentState.validate()) {
                    DateTime temp = DateTime(
                        _selectedDateTime.year,
                        _selectedDateTime.month,
                        _selectedDateTime.day,
                        time.hour,
                        time.minute);

                    Info newInfo = Info(
                        carriage: _carriageController.text,
                        seat: _seatController.text,
                        datetime: temp);
                    if (info != null) newInfo.id = info.id;

                    Navigator.of(context).pop(newInfo);
                  }
                },
                textColor: Colors.green,
                child: Text('OK'))
          ],
        );
      },
    );
  }

  void _loadStored() async {
    _db = DBHelper();
    await _db.init();
    List<Info> infoList = await _db.queryAll();
    print(infoList.length);
    setState(() {
      for (var info in infoList) {
        var key = DateTime.utc(info.datetime.year, info.datetime.month,
            info.datetime.day, 12, 0, 0);
        _events[key] = [info];
      }
    });
  }
}

class Info {
  int id;
  final DateTime datetime;
  final String carriage;
  final String seat;

  Info({this.id, this.datetime, this.carriage, this.seat});

  static Info fromMap(Map<String, dynamic> info) {
    return Info(
        id: info['id'],
        datetime: DateTime.tryParse(info['datetime']),
        carriage: info['carriage'],
        seat: info['seat']);
  }

  Map<String, dynamic> toMap() {
    String dtString = DateFormat('yyyy-MM-dd HH:mm').format(datetime);
    Map<String, dynamic> result = {
      'datetime': dtString,
      'carriage': carriage,
      'seat': seat
    };
    if (id != null) {
      result['id'] = id;
    }
    return result;
  }
}
