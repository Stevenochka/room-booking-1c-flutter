import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiBaseUrl = 'http://IP-Adress/room_booking/hs/api';

const String apiUser = 'dev';
const String apiPassword = '123';

String get basicAuthHeader {
  return 'Basic ${base64Encode(utf8.encode('$apiUser:$apiPassword'))}';
}

Map<String, String> get apiHeaders {
  return {'Authorization': basicAuthHeader};
}

Map<String, String> get apiJsonHeaders {
  return {'Content-Type': 'application/json', 'Authorization': basicAuthHeader};
}

void main() {
  runApp(const RoomBookingApp());
}

class RoomBookingApp extends StatelessWidget {
  const RoomBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Кабинеты',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4B2DBB)),
      ),
      home: const LoginPage(),
    );
  }
}

class AppUser {
  AppUser({required this.login, required this.name, required this.role});

  final String login;
  final String name;
  final String role;

  bool get isAdmin => role == 'admin';
}

class RoomInfo {
  RoomInfo({
    required this.number,
    required this.name,
    this.status = 'unknown',
    this.changedAt = '-',
    this.source = '-',
    this.reason = '',
    this.teacherName = '',
    this.teacherLogin = '',
    required this.capacity,
    required this.requiresKey,
    required this.keyLocation,
    required this.description,
    required this.equipmentText,
  });

  final String number;
  final String name;
  String status;
  String changedAt;
  String source;
  String reason;
  String teacherName;
  String teacherLogin;
  final int capacity;
  final bool requiresKey;
  final String keyLocation;
  final String description;
  final String equipmentText;
}

class BookingInfo {
  BookingInfo({
    required this.number,
    required this.start,
    required this.end,
    required this.teacherName,
    required this.teacherLogin,
    required this.subjectName,
    required this.groupName,
    required this.comment,
    required this.source,
  });

  final String number;
  final String start;
  final String end;
  final String teacherName;
  final String teacherLogin;
  final String subjectName;
  final String groupName;
  final String comment;
  final String source;
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController loginController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String messageText = '';

  String get loginUrl => '$apiBaseUrl/auth/login';

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final login = loginController.text.trim();
    final password = passwordController.text.trim();

    if (login.isEmpty || password.isEmpty) {
      setState(() {
        messageText = 'Введите логин и пароль';
      });
      return;
    }

    setState(() {
      isLoading = true;
      messageText = 'Выполняется вход...';
    });

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: apiJsonHeaders,
        body: jsonEncode({'login': login, 'password': password}),
      );

      if (response.body.trim().isEmpty) {
        setState(() {
          messageText =
              'Пустой ответ от 1С. Код ответа: ${response.statusCode}. Проверь IP и авторизацию HTTP-сервиса.';
        });
        return;
      }
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = AppUser(
          login: data['teacherLogin'] ?? '',
          name: data['teacherName'] ?? '',
          role: data['role'] ?? 'teacher',
        );

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => RoomsListPage(user: user)),
        );
      } else {
        setState(() {
          messageText = data['message'] ?? 'Ошибка входа';
        });
      }
    } catch (e) {
      setState(() {
        messageText = 'Ошибка подключения к 1С:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.meeting_room_outlined,
                  size: 76,
                  color: Color(0xFF4B2DBB),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Вход в систему',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF231A3D),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Бронирование и мониторинг кабинетов',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B6387), fontSize: 15),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: loginController,
                        decoration: InputDecoration(
                          labelText: 'Логин',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: isLoading ? null : login,
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Войти'),
                      ),
                    ],
                  ),
                ),
                if (messageText.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EEFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      messageText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF4A3F75),
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RoomsListPage extends StatefulWidget {
  const RoomsListPage({super.key, required this.user});

  final AppUser user;

  @override
  State<RoomsListPage> createState() => _RoomsListPageState();
}

class _RoomsListPageState extends State<RoomsListPage> {
  Timer? refreshTimer;

  // ВАЖНО: поставь свой рабочий базовый адрес 1С.
  // Пример: http://192.168.0.105/room_booking/hs/api

  final TextEditingController searchController = TextEditingController();

  List<RoomInfo> rooms = [];
  bool isLoading = true;
  String errorText = '';

  @override
  void initState() {
    super.initState();

    loadRoomsWithStatuses();

    refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => refreshStatusesOnly(),
    );

    searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    searchController.dispose();
    super.dispose();
  }

  String get roomsUrl => '$apiBaseUrl/rooms';

  String roomStatusUrl(String roomNumber) {
    return '$apiBaseUrl/rooms/$roomNumber/status';
  }

  Future<void> loadRoomsWithStatuses() async {
    setState(() {
      isLoading = true;
      errorText = '';
    });

    try {
      final response = await http.get(Uri.parse(roomsUrl), headers: apiHeaders);

      if (response.statusCode != 200) {
        setState(() {
          isLoading = false;
          errorText =
              'Ошибка загрузки кабинетов: ${response.statusCode}\n${response.body}';
        });
        return;
      }

      final data = jsonDecode(response.body);
      final List roomsFromServer = data['rooms'] ?? [];

      final loadedRooms = roomsFromServer.map<RoomInfo>((room) {
        return RoomInfo(
          number: room['number']?.toString() ?? '',
          name: room['name']?.toString() ?? '',
          status: room['status']?.toString() ?? 'free',
          changedAt: room['changedAt']?.toString() ?? '-',
          source: room['source']?.toString() ?? '-',
          reason: room['reason']?.toString() ?? '',
          teacherName: room['teacherName']?.toString() ?? '',
          teacherLogin: room['teacherLogin']?.toString() ?? '',

          capacity: int.tryParse(room['capacity']?.toString() ?? '0') ?? 0,
          requiresKey:
              room['requiresKey'] == true ||
              room['requiresKey']?.toString().toLowerCase() == 'true',
          keyLocation: room['keyLocation']?.toString() ?? '',
          description: room['description']?.toString() ?? '',
          equipmentText: room['equipmentText']?.toString() ?? '',
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        rooms = loadedRooms;
        isLoading = false;
      });

      await refreshStatusesOnly();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorText = 'Ошибка подключения к 1С:\n$e';
      });
    }
  }

  Future<void> refreshStatusesOnly() async {
    if (rooms.isEmpty) return;

    for (final room in rooms) {
      try {
        final response = await http.get(
          Uri.parse(roomStatusUrl(room.number)),
          headers: apiHeaders,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          room.status = data['status'] ?? 'unknown';
          room.changedAt = data['changedAt'] ?? '-';
          room.source = data['source'] ?? '-';
          room.reason = data['reason'] ?? '';
          room.teacherName = data['teacherName'] ?? '';
          room.teacherLogin = data['teacherLogin'] ?? '';
        } else {
          room.status = 'unknown';
          room.changedAt = '-';
          room.source = '-';
          room.reason = '';
          room.teacherName = '';
          room.teacherLogin = '';
        }
      } catch (_) {
        room.status = 'offline';
        room.changedAt = '-';
        room.source = '-';
        room.reason = '';
        room.teacherName = '';
        room.teacherLogin = '';
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  List<RoomInfo> get filteredRooms {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return rooms;
    }

    return rooms.where((room) {
      return room.number.toLowerCase().contains(query) ||
          room.name.toLowerCase().contains(query);
    }).toList();
  }

  String getStatusText(String status) {
    switch (status) {
      case 'free':
        return 'Свободен';
      case 'busy':
        return 'Занят';
      case 'closed':
        return 'Недоступен';
      case 'offline':
        return 'Нет связи';
      default:
        return 'Неизвестно';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'free':
        return const Color(0xFFB8F3D0);
      case 'busy':
        return const Color(0xFFFFC2C2);
      case 'closed':
        return const Color(0xFFFFD7A8);
      case 'offline':
        return const Color(0xFFD0D0D0);
      default:
        return const Color(0xFFDCE8FF);
    }
  }

  Color getStatusTextColor(String status) {
    switch (status) {
      case 'free':
        return const Color(0xFF177A3D);
      case 'busy':
        return const Color(0xFFB3261E);
      case 'closed':
        return const Color(0xFF9A4F00);
      case 'offline':
        return const Color(0xFF555555);
      default:
        return const Color(0xFF2257A3);
    }
  }

  Future<void> openRoomCard(RoomInfo room) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return RoomDetailsPage(
            room: room,
            apiBaseUrl: apiBaseUrl,
            user: widget.user,
          );
        },
      ),
    );

    await refreshStatusesOnly();
  }

  Future<void> logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выход'),
          content: const Text('Выйти из учётной записи?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleRooms = filteredRooms;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B168F), Color(0xFF5C35D5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Кабинеты',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${widget.user.name} • ${widget.user.isAdmin ? 'Администратор' : 'Преподаватель'}',
                              style: const TextStyle(
                                color: Color(0xFFE5DFFF),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: logout,
                        tooltip: 'Выйти',
                        icon: const Icon(Icons.logout, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Чтобы не дублировалось имя пользователя
                  //Text(
                  //  '${widget.user.name} • ${widget.user.isAdmin ? 'Администратор' : 'Преподаватель'}',
                  //  style: const TextStyle(
                  //    color: Color(0xFFE5DFFF),
                  //    fontSize: 15,
                  //    fontWeight: FontWeight.w600,
                  //  ),
                  //),
                  const SizedBox(height: 18),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск кабинета...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: loadRoomsWithStatuses,
                child: Builder(
                  builder: (context) {
                    if (isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (errorText.isNotEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const SizedBox(height: 80),
                          const Icon(
                            Icons.wifi_off,
                            size: 56,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            errorText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: loadRoomsWithStatuses,
                            child: const Text('Повторить'),
                          ),
                        ],
                      );
                    }

                    if (visibleRooms.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: const [
                          SizedBox(height: 80),
                          Icon(Icons.search_off, size: 56, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Кабинеты не найдены',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                      itemCount: visibleRooms.length,
                      itemBuilder: (context, index) {
                        final room = visibleRooms[index];

                        return RoomCard(
                          room: room,
                          statusText: getStatusText(room.status),
                          statusColor: getStatusColor(room.status),
                          statusTextColor: getStatusTextColor(room.status),
                          onTap: () => openRoomCard(room),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RoomDetailsPage extends StatefulWidget {
  const RoomDetailsPage({
    super.key,
    required this.room,
    required this.apiBaseUrl,
    required this.user,
  });

  final RoomInfo room;
  final String apiBaseUrl;
  final AppUser user;

  @override
  State<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends State<RoomDetailsPage> {
  Timer? refreshTimer;

  late String status;
  late String changedAt;
  late String source;
  late String reason;
  late String teacherName;
  late String teacherLogin;

  List<BookingInfo> bookings = [];
  bool isBookingsLoading = false;

  int selectedDetailsTab = 0;

  DateTime selectedBookingDate = DateTime.now();

  TimeOfDay bookingStartTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay bookingEndTime = const TimeOfDay(hour: 13, minute: 0);

  final TextEditingController bookingCommentController =
      TextEditingController();

  bool isBookingSending = false;

  bool isSending = false;
  String messageText = '';

  final List<String> closedReasons = [
    'ремонт',
    'уборка',
    'санобработка',
    'неисправно оборудование',
    'прочее',
  ];

  String selectedClosedReason = 'ремонт';

  String get roomStatusUrl {
    return '${widget.apiBaseUrl}/rooms/${widget.room.number}/status';
  }

  String get roomBookingsUrl {
    return '${widget.apiBaseUrl}/rooms/${widget.room.number}/bookings';
  }

  String get createBookingUrl {
    return '${widget.apiBaseUrl}/bookings';
  }

  String get cancelBookingUrl {
    return '${widget.apiBaseUrl}/bookings/cancel';
  }

  Future<void> loadBookings({bool silent = false}) async {
    if (!silent) {
      setState(() {
        isBookingsLoading = true;
      });
    }

    try {
      final response = await http.get(
        Uri.parse(roomBookingsUrl),
        headers: apiHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List bookingsFromServer = data['bookings'] ?? [];

        final loadedBookings = bookingsFromServer.map<BookingInfo>((booking) {
          return BookingInfo(
            number: booking['number'].toString(),
            start: booking['start'].toString(),
            end: booking['end'].toString(),
            teacherName: booking['teacherName'].toString(),
            teacherLogin: booking['teacherLogin']?.toString() ?? '',
            subjectName: booking['subjectName']?.toString() ?? '',
            groupName: booking['groupName']?.toString() ?? '',
            comment: booking['comment'].toString(),
            source: booking['source'].toString(),
          );
        }).toList();

        if (!mounted) return;

        setState(() {
          bookings = loadedBookings;
          isBookingsLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          bookings = [];
          isBookingsLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        bookings = [];
        isBookingsLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    status = widget.room.status;
    changedAt = widget.room.changedAt;
    source = widget.room.source;
    reason = widget.room.reason;
    teacherName = widget.room.teacherName;
    teacherLogin = widget.room.teacherLogin;

    if (closedReasons.contains(reason)) {
      selectedClosedReason = reason;
    }

    loadStatus();
    loadBookings();

    refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      loadStatus(silent: true);
      loadBookings(silent: true);
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    bookingCommentController.dispose();
    super.dispose();
  }

  Future<void> loadStatus({bool silent = false}) async {
    if (!silent) {
      setState(() {
        messageText = 'Обновляю статус...';
      });
    }

    try {
      final response = await http.get(
        Uri.parse(roomStatusUrl),
        headers: apiHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          status = data['status'] ?? 'unknown';
          changedAt = data['changedAt'] ?? '-';
          source = data['source'] ?? '-';
          reason = data['reason'] ?? '';
          teacherName = data['teacherName'] ?? '';
          teacherLogin = data['teacherLogin'] ?? '';

          widget.room.status = status;
          widget.room.changedAt = changedAt;
          widget.room.source = source;
          widget.room.reason = reason;
          widget.room.teacherName = teacherName;
          widget.room.teacherLogin = teacherLogin;

          if (!silent) {
            messageText = 'Статус обновлён';
          }
        });
      } else {
        if (!mounted) return;

        setState(() {
          messageText = 'Ошибка получения статуса: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!silent && mounted) {
        setState(() {
          messageText = 'Ошибка подключения:\n$e';
        });
      }
    }
  }

  Future<void> pickBookingDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final currentSelectedDate = DateUtils.dateOnly(selectedBookingDate);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentSelectedDate.isBefore(today)
          ? today
          : currentSelectedDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        selectedBookingDate = DateUtils.dateOnly(pickedDate);
        messageText = 'Выбрана дата: ${formatSelectedDate()}';
      });
    }
  }

  Future<void> pickStartTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: bookingStartTime,
    );

    if (pickedTime != null) {
      setState(() {
        bookingStartTime = pickedTime;
      });
    }
  }

  Future<void> pickEndTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: bookingEndTime,
    );

    if (pickedTime != null) {
      setState(() {
        bookingEndTime = pickedTime;
      });
    }
  }

  Future<void> createBooking() async {
    final startDateTime = buildBookingDateTime(bookingStartTime);
    final endDateTime = buildBookingDateTime(bookingEndTime);

    final now = DateTime.now();

    if (startDateTime.isBefore(now)) {
      setState(() {
        messageText = 'Нельзя создать бронирование на прошедшее время';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нельзя создать бронирование на прошедшее время'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (!endDateTime.isAfter(startDateTime)) {
      setState(() {
        messageText = 'Время окончания должно быть позже времени начала';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Время окончания должно быть позже времени начала'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      isBookingSending = true;
      messageText = 'Создаю бронирование...';
    });

    try {
      final response = await http.post(
        Uri.parse(createBookingUrl),
        headers: apiJsonHeaders,
        body: jsonEncode({
          'room': widget.room.number,
          'teacherLogin': widget.user.login,
          'start': formatDateTimeForApi(startDateTime),
          'end': formatDateTimeForApi(endDateTime),
          'comment': bookingCommentController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        bookingCommentController.clear();

        await loadBookings(silent: true);
        await loadStatus(silent: true);

        if (!mounted) return;

        setState(() {
          selectedDetailsTab = 1;
        });

        if (!mounted) return;

        setState(() {
          messageText = data['message'] ?? 'Бронирование создано';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Бронирование создано'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        String prettyMessage = data['message'] ?? 'Не удалось создать бронь';

        if (data['error'] == 'booking_conflict') {
          final currentTeacher = data['currentTeacher'] ?? '';

          prettyMessage = 'На выбранное время кабинет уже забронирован';

          if (currentTeacher.toString().trim().isNotEmpty) {
            prettyMessage += '\nПреподаватель: $currentTeacher';
          }
        } else if (data['error'] == 'room_closed') {
          final reason = data['reason'] ?? '';

          prettyMessage = 'Кабинет временно недоступен для бронирования';

          if (reason.toString().trim().isNotEmpty) {
            prettyMessage += '\nПричина: $reason';
          }
        }

        if (!mounted) return;

        setState(() {
          messageText = prettyMessage;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prettyMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messageText = 'Ошибка создания бронирования:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isBookingSending = false;
        });
      }
    }
  }

  Future<void> cancelBooking(BookingInfo booking) async {
    setState(() {
      messageText = 'Отменяю бронирование...';
    });

    try {
      final response = await http.post(
        Uri.parse(cancelBookingUrl),
        headers: apiJsonHeaders,
        body: jsonEncode({
          'bookingNumber': booking.number,
          'teacherLogin': widget.user.login,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        await loadBookings();
        await loadStatus(silent: true);

        if (!mounted) return;

        setState(() {
          messageText = data['message'] ?? 'Бронирование отменено';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Бронирование отменено'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final prettyMessage =
            data['message'] ?? 'Не удалось отменить бронирование';

        if (!mounted) return;

        setState(() {
          messageText = prettyMessage;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prettyMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messageText = 'Ошибка отмены бронирования:\n$e';
      });
    }
  }

  Future<void> sendStatus(String newStatus) async {
    setState(() {
      isSending = true;
      messageText = 'Отправляю изменение...';
    });

    try {
      final response = await http.post(
        Uri.parse(roomStatusUrl),
        headers: apiJsonHeaders,
        body: jsonEncode({
          'room': widget.room.number,
          'status': newStatus,
          'source': 'mobile',
          'reason': newStatus == 'closed' ? selectedClosedReason : '',
          'teacherLogin': widget.user.login,
        }),
      );

      if (response.statusCode == 200) {
        await loadStatus(silent: true);

        if (!mounted) return;

        setState(() {
          messageText = 'Статус успешно изменён';
        });
      } else {
        String prettyMessage = 'Не удалось изменить статус кабинета';

        try {
          final errorData = jsonDecode(response.body);

          final errorCode = errorData['error'] ?? '';
          final serverMessage = errorData['message'] ?? '';
          final currentTeacher = errorData['currentTeacher'] ?? '';
          final requestTeacher = errorData['requestTeacher'] ?? '';

          if (errorCode == 'room_already_busy') {
            prettyMessage =
                'Кабинет уже занят другим преподавателем'
                '${currentTeacher.toString().trim().isNotEmpty ? '\nСейчас занят: $currentTeacher' : ''}';
          } else if (errorCode == 'only_owner_can_release') {
            prettyMessage =
                'Освободить кабинет может только преподаватель, который его занял'
                '${currentTeacher.toString().trim().isNotEmpty ? '\nЗанял кабинет: $currentTeacher' : ''}'
                '${requestTeacher.toString().trim().isNotEmpty ? '\nВаш преподаватель: $requestTeacher' : ''}';
          } else if (serverMessage.toString().trim().isNotEmpty) {
            prettyMessage = serverMessage;
          } else {
            prettyMessage = 'Ошибка изменения: ${response.statusCode}';
          }
        } catch (_) {
          prettyMessage = 'Ошибка изменения: ${response.statusCode}';
        }

        if (!mounted) return;

        setState(() {
          messageText = prettyMessage;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(prettyMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        messageText = 'Ошибка POST-запроса:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  String getStatusText(String value) {
    switch (value) {
      case 'free':
        return 'Свободен';
      case 'busy':
        return 'Занят';
      case 'closed':
        return 'Недоступен';
      case 'offline':
        return 'Нет связи';
      default:
        return 'Неизвестно';
    }
  }

  String getSourceText(String value) {
    switch (value) {
      case 'mobile':
        return 'Мобильное приложение';
      case 'desktop':
        return 'ПК-форма 1С';
      case 'booking':
        return 'По бронированию';
      case 'schedule':
        return 'Расписание';
      case 'system':
        return 'Система';
      default:
        return value.trim().isEmpty ? '-' : value;
    }
  }

  Color getStatusColor(String value) {
    switch (value) {
      case 'free':
        return const Color(0xFFB8F3D0);
      case 'busy':
        return const Color(0xFFFFC2C2);
      case 'closed':
        return const Color(0xFFFFD7A8);
      case 'offline':
        return const Color(0xFFD0D0D0);
      default:
        return const Color(0xFFDCE8FF);
    }
  }

  Color getStatusTextColor(String value) {
    switch (value) {
      case 'free':
        return const Color(0xFF177A3D);
      case 'busy':
        return const Color(0xFFB3261E);
      case 'closed':
        return const Color(0xFF9A4F00);
      case 'offline':
        return const Color(0xFF555555);
      default:
        return const Color(0xFF2257A3);
    }
  }

  String formatDateOnly(String value) {
    final cleanValue = value.trim();

    // Формат от 1С: 26.05.2026 12:00:00
    if (cleanValue.length >= 10 &&
        cleanValue[2] == '.' &&
        cleanValue[5] == '.') {
      return cleanValue.substring(0, 10);
    }

    // ISO-формат: 2026-05-26 12:00:00
    if (cleanValue.length >= 10 &&
        cleanValue[4] == '-' &&
        cleanValue[7] == '-') {
      final year = cleanValue.substring(0, 4);
      final month = cleanValue.substring(5, 7);
      final day = cleanValue.substring(8, 10);

      return '$day.$month.$year';
    }

    return cleanValue;
  }

  String formatTimeOnly(String value) {
    final cleanValue = value.trim();

    if (cleanValue.length >= 16) {
      return cleanValue.substring(11, 16);
    }

    return cleanValue;
  }

  String formatBookingTimeRange(BookingInfo booking) {
    return '${formatDateOnly(booking.start)} ${formatTimeOnly(booking.start)} - ${formatTimeOnly(booking.end)}';
  }

  String twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  DateTime buildBookingDateTime(TimeOfDay time) {
    return DateTime(
      selectedBookingDate.year,
      selectedBookingDate.month,
      selectedBookingDate.day,
      time.hour,
      time.minute,
    );
  }

  String formatDateTimeForApi(DateTime value) {
    return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)} '
        '${twoDigits(value.hour)}:${twoDigits(value.minute)}:00';
  }

  String formatSelectedDate() {
    return '${twoDigits(selectedBookingDate.day)}.'
        '${twoDigits(selectedBookingDate.month)}.'
        '${selectedBookingDate.year}';
  }

  String formatTimeOfDayValue(TimeOfDay value) {
    return '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }

  Widget buildDetailsTabButton({
    required String title,
    required IconData icon,
    required int index,
  }) {
    final bool isSelected = selectedDetailsTab == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            selectedDetailsTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4B22C9) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : const Color(0xFF5E587A),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF5E587A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDetailsTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          buildDetailsTabButton(
            title: 'Кабинет',
            icon: Icons.meeting_room_outlined,
            index: 0,
          ),
          buildDetailsTabButton(
            title: isBookingsLoading
                ? 'Бронирования'
                : 'Брони (${bookings.length})',
            icon: Icons.event_note_outlined,
            index: 1,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = status == 'closed';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B168F), Color(0xFF5C35D5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.room.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Номер кабинета: ${widget.room.number}',
                    style: const TextStyle(
                      color: Color(0xFFE5DFFF),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildDetailsTabs(),

                    const SizedBox(height: 18),

                    if (selectedDetailsTab == 0) ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Текущее состояние',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF231A3D),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: getStatusColor(status),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                getStatusText(status),
                                style: TextStyle(
                                  color: getStatusTextColor(status),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _DetailRow(
                              icon: Icons.schedule,
                              label: 'Дата изменения',
                              value: changedAt,
                            ),
                            const SizedBox(height: 10),
                            _DetailRow(
                              icon: Icons.sync_alt,
                              label: 'Источник',
                              value: getSourceText(source),
                            ),

                            if (teacherName.trim().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              _DetailRow(
                                icon: Icons.person_outline,
                                label: 'Преподаватель',
                                value: teacherName,
                              ),
                            ],

                            if (isClosed) ...[
                              const SizedBox(height: 10),
                              _DetailRow(
                                icon: Icons.info_outline,
                                label: 'Причина',
                                value: reason.trim().isEmpty ? '-' : reason,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Описание кабинета',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF231A3D),
                              ),
                            ),

                            const SizedBox(height: 14),

                            _DetailRow(
                              icon: Icons.groups_outlined,
                              label: 'Вместимость',
                              value: widget.room.capacity > 0
                                  ? '${widget.room.capacity} человек'
                                  : 'не указана',
                            ),

                            _DetailRow(
                              icon: Icons.vpn_key_outlined,
                              label: 'Ключ',
                              value: widget.room.requiresKey
                                  ? 'требуется'
                                  : 'не требуется',
                            ),

                            if (widget.room.requiresKey &&
                                widget.room.keyLocation.trim().isNotEmpty)
                              _DetailRow(
                                icon: Icons.location_on_outlined,
                                label: 'Где ключ',
                                value: widget.room.keyLocation,
                              ),

                            if (widget.room.equipmentText
                                .trim()
                                .isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.devices_other_outlined,
                                          size: 20,
                                          color: Color(0xFF6E5AA6),
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Оснащение',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF5E587A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 30),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: widget.room.equipmentText
                                            .split(';')
                                            .map((item) => item.trim())
                                            .where((item) => item.isNotEmpty)
                                            .map(
                                              (item) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                child: Text(
                                                  '• $item',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF231A3D),
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            if (widget.room.description.trim().isNotEmpty)
                              _DetailRow(
                                icon: Icons.notes_outlined,
                                label: 'Описание',
                                value: widget.room.description,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Создать бронирование',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF231A3D),
                              ),
                            ),

                            const SizedBox(height: 16),

                            OutlinedButton.icon(
                              onPressed: isBookingSending
                                  ? null
                                  : pickBookingDate,
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: Text('Дата: ${formatSelectedDate()}'),
                            ),

                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: isBookingSending
                                        ? null
                                        : pickStartTime,
                                    icon: const Icon(Icons.access_time),
                                    label: Text(
                                      'Начало: ${formatTimeOfDayValue(bookingStartTime)}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: isBookingSending
                                        ? null
                                        : pickEndTime,
                                    icon: const Icon(Icons.access_time_filled),
                                    label: Text(
                                      'Конец: ${formatTimeOfDayValue(bookingEndTime)}',
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            TextField(
                              controller: bookingCommentController,
                              enabled: !isBookingSending,
                              maxLines: 2,
                              decoration: InputDecoration(
                                labelText: 'Комментарий',
                                hintText: 'Например: консультация',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            ElevatedButton.icon(
                              onPressed: isBookingSending
                                  ? null
                                  : createBooking,
                              icon: isBookingSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.event_available_outlined),
                              label: Text(
                                isBookingSending
                                    ? 'Создание...'
                                    : 'Забронировать',
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (widget.user.isAdmin) ...[
                        const SizedBox(height: 18),

                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Административная блокировка',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF231A3D),
                                ),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'Используется, если кабинет временно недоступен: ремонт, уборка, санобработка или неисправность оборудования.',
                                style: TextStyle(
                                  color: Color(0xFF6B6387),
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),

                              const SizedBox(height: 16),

                              DropdownButtonFormField<String>(
                                value: selectedClosedReason,
                                decoration: InputDecoration(
                                  labelText: 'Причина недоступности',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                items: closedReasons.map((item) {
                                  return DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  );
                                }).toList(),
                                onChanged: isSending
                                    ? null
                                    : (value) {
                                        if (value != null) {
                                          setState(() {
                                            selectedClosedReason = value;
                                          });
                                        }
                                      },
                              ),

                              const SizedBox(height: 16),

                              ElevatedButton.icon(
                                onPressed: isSending
                                    ? null
                                    : () => sendStatus('closed'),
                                icon: const Icon(Icons.block_outlined),
                                label: const Text(
                                  'Сделать кабинет недоступным',
                                ),
                              ),

                              if (status == 'closed') ...[
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: isSending
                                      ? null
                                      : () => sendStatus('free'),
                                  icon: const Icon(Icons.lock_open_outlined),
                                  label: const Text('Снять блокировку'),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ближайшие бронирования',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF231A3D),
                              ),
                            ),
                            const SizedBox(height: 14),

                            if (isBookingsLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (bookings.isEmpty)
                              const Text(
                                'Ближайших бронирований нет',
                                style: TextStyle(
                                  color: Color(0xFF6B6387),
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              Column(
                                children: bookings.map((booking) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF6F3FF),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.event_available_outlined,
                                          color: Color(0xFF6556A8),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  formatBookingTimeRange(
                                                    booking,
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF231A3D),
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                booking.teacherName,
                                                style: const TextStyle(
                                                  color: Color(0xFF5E587A),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),

                                              if (booking.subjectName
                                                  .trim()
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Предмет: ${booking.subjectName}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF5E587A),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],

                                              if (booking.groupName
                                                  .trim()
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Группа: ${booking.groupName}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF5E587A),
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],

                                              if (booking.comment
                                                  .trim()
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  booking.comment,
                                                  style: const TextStyle(
                                                    color: Color(0xFF7A7196),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],

                                              if (widget.user.isAdmin ||
                                                  booking.teacherLogin ==
                                                      widget.user.login) ...[
                                                const SizedBox(height: 10),
                                                OutlinedButton.icon(
                                                  onPressed: () =>
                                                      cancelBooking(booking),
                                                  icon: const Icon(
                                                    Icons.cancel_outlined,
                                                  ),
                                                  label: const Text('Отменить'),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ],

                    if (messageText.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EEFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          messageText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF4A3F75),
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF6E5AA6)),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5E587A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF231A3D),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.statusText,
    required this.statusColor,
    required this.statusTextColor,
    required this.onTap,
  });

  final RoomInfo room;
  final String statusText;
  final Color statusColor;
  final Color statusTextColor;
  final VoidCallback onTap;

  String getSourceText(String value) {
    switch (value) {
      case 'mobile':
        return 'Мобильное приложение';
      case 'desktop':
        return 'ПК-форма 1С';
      case 'booking':
        return 'По бронированию';
      case 'schedule':
        return 'Расписание';
      case 'system':
        return 'Система';
      default:
        return value.trim().isEmpty || value == '-'
            ? 'источник не указан'
            : value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final showReason = room.status == 'closed' && room.reason.trim().isNotEmpty;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF231A3D),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _RoomMetaItem(
                    icon: Icons.meeting_room_outlined,
                    text: '№ ${room.number}',
                  ),
                  if (room.teacherName.trim().isNotEmpty)
                    _RoomMetaItem(
                      icon: Icons.person_outline,
                      text: room.teacherName,
                    ),
                  _RoomMetaItem(
                    icon: Icons.sync_alt,
                    text: getSourceText(room.source),
                  ),
                  if (room.changedAt != '-')
                    _RoomMetaItem(icon: Icons.schedule, text: room.changedAt),
                ],
              ),
              if (showReason) ...[
                const SizedBox(height: 10),
                _RoomMetaItem(
                  icon: Icons.info_outline,
                  text: 'Причина: ${room.reason}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomMetaItem extends StatelessWidget {
  const _RoomMetaItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF6556A8)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF5E587A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
