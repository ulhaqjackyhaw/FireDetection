import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:appmonitor/firebase_options.dart'; // Pastikan file ini ada dan benar
// Impor untuk Int64List (digunakan untuk pola getar kustom jika diinginkan)
import 'dart:typed_data'; // Ditambahkan untuk Int64List jika Anda ingin pola getar kustom

// Inisialisasi plugin notifikasi lokal
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Kelas model FireDetectionData
class FireDetectionData {
  final bool alarmActive;
  final double fuzzyDangerLevel;
  final String fuzzyStatus;
  final int gas;
  final double humidity;
  final bool irDetectedFire;
  final double temperature;
  final DateTime timestamp;

  FireDetectionData({
    required this.alarmActive,
    required this.fuzzyDangerLevel,
    required this.fuzzyStatus,
    required this.gas,
    required this.humidity,
    required this.irDetectedFire,
    required this.temperature,
    required this.timestamp,
  });

  factory FireDetectionData.fromMap(Map<dynamic, dynamic> map) {
    return FireDetectionData(
      alarmActive: map['alarm_active'] ?? false,
      fuzzyDangerLevel:
          double.tryParse(map['fuzzy_danger_level'].toString()) ?? 0.0,
      fuzzyStatus: map['fuzzy_status'] ?? 'UNKNOWN',
      gas: map['gas'] ?? 0,
      humidity: double.tryParse(map['humidity'].toString()) ?? 0.0,
      irDetectedFire: map['ir_detected_fire'] ?? false,
      temperature: double.tryParse(map['temperature'].toString()) ?? 0.0,
      timestamp:
          DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher'); // Pastikan ikon ini ada
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fire Detection Monitoring',
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A506B), // Warna dasar baru (biru keabuan)
          brightness: Brightness.light,
          primary: const Color(0xFF3A506B), // Biru keabuan tua
          secondary: const Color(0xFF1C7A71), // Teal
          surface: Colors.white, // Latar belakang kartu
          onSurface: const Color(0xFF333333), // Warna teks utama pada kartu
          background: const Color(0xFFF0F4F8), // Latar belakang scaffold
          onBackground: const Color(0xFF333333), // Warna teks pada scaffold
          error: const Color(0xFFD32F2F),
        ),
        scaffoldBackgroundColor:
            const Color(0xFFF0F4F8), // Latar belakang lebih terang
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3A506B), // Primary color
          foregroundColor: Colors.white, // Warna teks dan ikon di AppBar
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          color: Colors.white, // Latar belakang kartu
          shadowColor:
              Colors.blueGrey.withOpacity(0.2), // Bayangan lebih lembut
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222E3A)),
          titleLarge: TextStyle(
              // Digunakan untuk judul di kartu
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222E3A)),
          titleMedium: TextStyle(
              // Untuk sub-judul
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333)),
          bodyMedium:
              TextStyle(fontSize: 15, color: Color(0xFF555555), height: 1.4),
          labelLarge: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1C7A71), // Secondary color
          unselectedItemColor: Colors.blueGrey.shade300,
          elevation: 8,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref().child('fire_detection');
  List<FireDetectionData> _historicalData = [];
  static const int maxHistoricalData = 20;
  FireDetectionData? _latestData;
  final PageStorageBucket _bucket = PageStorageBucket();
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      DashboardPage(
          key: const PageStorageKey('dashboardPage'),
          latestData: _latestData,
          historicalData: _historicalData,
          databaseRef: _databaseRef),
      ChartsPage(
          key: const PageStorageKey('chartsPage'),
          latestData: _latestData,
          historicalData: _historicalData),
      RiskInfoPage(key: const PageStorageKey('riskInfoPage')),
    ];

    _databaseRef.onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        final data = FireDetectionData.fromMap(event.snapshot.value as Map);
        setState(() {
          _latestData = data;
          _updateHistoricalData(data);
          // Rebuild pages with new data
          _pages = <Widget>[
            DashboardPage(
                key: const PageStorageKey('dashboardPage'),
                latestData: _latestData,
                historicalData: _historicalData,
                databaseRef: _databaseRef),
            ChartsPage(
                key: const PageStorageKey('chartsPage'),
                latestData: _latestData,
                historicalData: _historicalData),
            RiskInfoPage(key: const PageStorageKey('riskInfoPage')),
          ];
        });
        _checkAndShowNotification(data);
      } else if (mounted) {
        setState(() {
          _latestData = null;
          _pages = <Widget>[
            DashboardPage(
                key: const PageStorageKey('dashboardPage'),
                latestData: _latestData,
                historicalData: _historicalData,
                databaseRef: _databaseRef),
            ChartsPage(
                key: const PageStorageKey('chartsPage'),
                latestData: _latestData,
                historicalData: _historicalData),
            RiskInfoPage(key: const PageStorageKey('riskInfoPage')),
          ];
        });
      }
    });
  }

  void _updateHistoricalData(FireDetectionData newData) {
    _historicalData.add(newData);
    if (_historicalData.length > maxHistoricalData) {
      _historicalData.removeAt(0);
    }
  }

  void _checkAndShowNotification(FireDetectionData data) {
    String? notificationTitle;
    String? notificationBody;
    String? soundName; // Nama file suara

    bool shouldNotify = false;
    if (data.fuzzyStatus == 'WASPADA') {
      notificationTitle = 'Peringatan: Status Waspada Terdeteksi!';
      notificationBody =
          'Tingkat bahaya: {data.fuzzyDangerLevel.toStringAsFixed(1)}%. Suhu: {data.temperature.toStringAsFixed(1)} b0C, Gas: {data.gas} ppm. Harap periksa kondisi sekitar.';
      soundName = 'suara_waspada'; // Nama file suara untuk WASPADA (tanpa ekstensi)
      shouldNotify = true;
    } else if (data.fuzzyStatus == 'BAHAYA') {
      notificationTitle = '🚨 DARURAT: STATUS BAHAYA TERDETEKSI! 🚨';
      notificationBody =
          'Tingkat bahaya SANGAT TINGGI: {data.fuzzyDangerLevel.toStringAsFixed(1)}%. SEGERA LAKUKAN EVAKUASI dan hubungi pihak berwenang!';
      soundName = 'alarm_kebakaran'; // Nama file suara untuk BAHAYA (tanpa ekstensi)
      shouldNotify = true;
    }

    if (shouldNotify && notificationTitle != null && notificationBody != null && soundName != null) {
      _showNotification(notificationTitle, notificationBody, soundName);
    }
  }

  Future<void> _showNotification(String title, String body, String soundName) async {
    final Int64List vibrationPattern = Int64List.fromList([0, 500, 500, 500]);

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'fire_detection_channel_critical',
      'Peringatan Deteksi Api Kritis',
      channelDescription:
          'Notifikasi penting untuk peringatan dan bahaya deteksi api.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound(soundName),
      vibrationPattern: vibrationPattern,
      ticker: 'Peringatan Api!',
      color: Colors.red,
      ledColor: Colors.red,
      ledOnMs: 1000,
      ledOffMs: 500,
    );
    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'fire_alert_detail',
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(_selectedIndex)),
        centerTitle: true,
      ),
      body: PageStorage(
        bucket: _bucket,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            activeIcon: Icon(Icons.insights_rounded),
            label: 'Grafik',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_rounded),
            activeIcon: Icon(Icons.warning_amber_rounded),
            label: 'Info Risiko',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard Monitoring';
      case 1:
        return 'Analisis Grafik Sensor';
      case 2:
        return 'Informasi Tingkat Risiko';
      default:
        return 'Monitoring Deteksi Api';
    }
  }
}

// --- DASHBOARD PAGE ---
class DashboardPage extends StatelessWidget {
  final FireDetectionData? latestData;
  final List<FireDetectionData> historicalData;
  final DatabaseReference databaseRef;

  const DashboardPage({
    super.key,
    required this.latestData,
    required this.historicalData,
    required this.databaseRef,
  });

  Widget _buildStatusIndicator(
      BuildContext context, String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.5)),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
      ),
    );
  }

  Widget _buildCurrentDataCard(BuildContext context, FireDetectionData data) {
    Color statusColor;
    IconData statusIcon;
    switch (data.fuzzyStatus) {
      case 'AMAN':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.shield_rounded;
        break;
      case 'WASPADA':
        statusColor = Colors.orange.shade700;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'BAHAYA':
        statusColor = Colors.red.shade700;
        statusIcon = Icons.dangerous_rounded;
        break;
      default:
        statusColor = Colors.grey.shade600;
        statusIcon = Icons.help_outline_rounded;
    }

    return Card(
      elevation: Theme.of(context).cardTheme.elevation ?? 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
              Theme.of(context).cardTheme.shape != null
                  ? (Theme.of(context).cardTheme.shape
                          as RoundedRectangleBorder)
                      .borderRadius
                      .resolve(Directionality.of(context))
                      .topLeft
                      .x
                  : 16),
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.05),
              Theme.of(context).colorScheme.surface.withOpacity(0.5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 32),
                    const SizedBox(width: 12),
                    Text('Status Saat Ini',
                        style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                _buildStatusIndicator(context, data.fuzzyStatus, statusColor),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade300),
            const SizedBox(height: 12),
            _buildDataRow(context, Icons.thermostat_rounded, 'Suhu:',
                '${data.temperature.toStringAsFixed(1)} °C',
                valueColor: statusColor),
            _buildDataRow(context, Icons.water_drop_outlined, 'Kelembaban:',
                '${data.humidity.toStringAsFixed(1)} %'),
            _buildDataRow(
                context, Icons.cloud_outlined, 'Kadar Gas:', '${data.gas} ppm',
                valueColor: data.gas > 600
                    ? Colors.orange.shade700
                    : null), // Contoh pewarnaan gas
            _buildDataRow(context, Icons.local_fire_department_rounded,
                'Level Bahaya:', '${data.fuzzyDangerLevel.toStringAsFixed(1)}%',
                valueColor: statusColor),
            _buildDataRow(context, Icons.visibility_rounded, 'Deteksi IR:',
                data.irDetectedFire ? 'TERDETEKSI' : 'AMAN',
                valueColor: data.irDetectedFire
                    ? Colors.red.shade700
                    : Colors.green.shade600),
            _buildDataRow(
                context,
                data.alarmActive
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                'Alarm:',
                data.alarmActive ? 'AKTIF' : 'MATI',
                valueColor: data.alarmActive
                    ? Colors.red.shade700
                    : Colors.green.shade600),
            _buildDataRow(context, Icons.access_time_rounded, 'Waktu Update:',
                DateFormat('dd MMM yyyy, HH:mm:ss').format(data.timestamp)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(
      BuildContext context, IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
              size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (latestData != null)
            _buildCurrentDataCard(context, latestData!)
          else if (latestData == null) // No need to check databaseRef here
            StreamBuilder(
              // Keep StreamBuilder for initial loading or if latestData becomes null
              stream: databaseRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(height: 16),
                          Text('Memuat data terbaru...',
                              style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                              size: 48),
                          const SizedBox(height: 16),
                          Text('Gagal memuat data',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error)),
                          const SizedBox(height: 8),
                          Text('${snapshot.error}',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                } else if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off_rounded,
                              color: Colors.grey.shade400, size: 48),
                          const SizedBox(height: 16),
                          Text('Tidak ada data tersedia',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          Text('Pastikan sensor terhubung dan mengirim data.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade500),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }
                final data = FireDetectionData.fromMap(
                    snapshot.data!.snapshot.value as Map);
                return _buildCurrentDataCard(context, data);
              },
            )
          else // This case should ideally not be reached if stream handling is robust
            const Center(child: Text('Tidak ada data tersedia.')),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    "Selamat Datang!",
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Aplikasi ini memonitor kondisi lingkungan untuk deteksi dini kebakaran. Gunakan tab di bawah untuk navigasi.",
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (historicalData.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      "Ringkasan Historis (${historicalData.length} data terakhir):",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildDataRow(
                      context,
                      Icons.thermostat_auto_rounded,
                      "Suhu Rata-rata:",
                      "${(historicalData.map((e) => e.temperature).reduce((a, b) => a + b) / historicalData.length).toStringAsFixed(1)} °C",
                    ),
                    _buildDataRow(
                        context,
                        Icons.task_alt_rounded,
                        "Status Terakhir:",
                        historicalData.last.fuzzyStatus.toUpperCase(),
                        valueColor: historicalData.last.fuzzyStatus == 'AMAN'
                            ? Colors.green.shade600
                            : (historicalData.last.fuzzyStatus == 'WASPADA'
                                ? Colors.orange.shade700
                                : Colors.red.shade700)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- CHARTS PAGE ---
class ChartsPage extends StatelessWidget {
  final FireDetectionData? latestData;
  final List<FireDetectionData> historicalData;

  const ChartsPage({
    super.key,
    this.latestData,
    required this.historicalData,
  });

  Widget _buildChartCard(
      BuildContext context, String title, IconData icon, Widget chartWidget,
      {List<Widget>? legends}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon,
                    color: Theme.of(context).colorScheme.secondary, size: 28),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 24),
            chartWidget,
            if (legends != null && legends.isNotEmpty) ...[
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 8,
                children: legends,
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    if (historicalData.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Text('Data tidak cukup untuk menampilkan grafik garis.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.grey.shade600)),
      ));
    }

    List<FlSpot> temperatureSpots = [];
    List<FlSpot> humiditySpots = [];
    List<FlSpot> gasSpots = [];
    double maxY = 100.0;
    if (historicalData.isNotEmpty) {
      double maxTemp = historicalData.map((e) => e.temperature).reduce(max);
      double maxHum = historicalData.map((e) => e.humidity).reduce(max);
      double maxGas = historicalData.map((e) => e.gas.toDouble()).reduce(max);
      maxY = [maxTemp, maxHum, maxGas, 50.0].reduce(max) *
          1.2; // Ensure a minimum and add padding
      if (maxY < 50) maxY = 50;
      if (maxY == 0 && historicalData.isNotEmpty)
        maxY = 100; // handle if all data is zero
    }

    for (int i = 0; i < historicalData.length; i++) {
      temperatureSpots.add(FlSpot(i.toDouble(), historicalData[i].temperature));
      humiditySpots.add(FlSpot(i.toDouble(), historicalData[i].humidity));
      gasSpots.add(FlSpot(i.toDouble(), historicalData[i].gas.toDouble()));
    }

    final tempColor = Colors.red.shade400;
    final humColor = Colors.blue.shade400;
    final gasColor = Colors.green.shade500;

    return AspectRatio(
      aspectRatio: 1.6,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                  color: Colors.grey.shade300.withOpacity(0.5), strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < historicalData.length) {
                    int dataCount = historicalData.length;
                    int interval = (dataCount / 4).ceil().clamp(1, dataCount);
                    if (value.toInt() % interval == 0 ||
                        value.toInt() == dataCount - 1) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('HH:mm')
                              .format(historicalData[value.toInt()].timestamp),
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700),
                        ),
                      );
                    }
                  }
                  return const Text('');
                },
                interval: 1,
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                reservedSize: 40,
                interval: (maxY / 5)
                    .ceilToDouble()
                    .clamp(1.0, maxY > 0 ? maxY : 10.0),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade300, width: 1)),
          minX: 0,
          maxX: max((historicalData.length - 1).toDouble(), 0),
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            _lineBarData(temperatureSpots, tempColor),
            _lineBarData(humiditySpots, humColor),
            _lineBarData(gasSpots, gasColor),
          ],
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) =>
                  Colors.blueGrey.shade800.withOpacity(0.9),
              tooltipPadding: const EdgeInsets.all(10),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  String seriesName = "";
                  if (spot.barIndex == 0)
                    seriesName = "Suhu: ";
                  else if (spot.barIndex == 1)
                    seriesName = "Lembab: ";
                  else if (spot.barIndex == 2) seriesName = "Gas: ";
                  return LineTooltipItem(
                    '$seriesName${spot.y.toStringAsFixed(1)}',
                    const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData _lineBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3.5,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.15)),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    // Only 3 statuses: AMAN, WASPADA, BAHAYA
    final List<String> statuses = ['AMAN', 'WASPADA', 'BAHAYA'];
    final Map<String, int> statusCounts = {
      'AMAN': 0,
      'WASPADA': 0,
      'BAHAYA': 0,
    };
    if (historicalData.isEmpty && latestData != null) {
      if (statusCounts.containsKey(latestData!.fuzzyStatus)) {
        statusCounts[latestData!.fuzzyStatus] = 1;
      }
    } else {
      for (var data in historicalData) {
        if (statusCounts.containsKey(data.fuzzyStatus)) {
          statusCounts[data.fuzzyStatus] =
              (statusCounts[data.fuzzyStatus] ?? 0) + 1;
        }
      }
    }

    final Map<String, Color> statusColors = {
      'AMAN': Colors.green.shade500,
      'WASPADA': Colors.orange.shade600,
      'BAHAYA': Colors.red.shade600,
    };

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < statuses.length; i++) {
      String status = statuses[i];
      int count = statusCounts[status]!;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: statusColors[status],
              width: 22,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

    double maxYBars = statusCounts.values.isNotEmpty
        ? statusCounts.values.reduce(max).toDouble() * 1.2
        : 5.0;
    if (maxYBars < 5) maxYBars = 5;

    return AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade300.withOpacity(0.5),
                  strokeWidth: 1)),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < statuses.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        statuses[value.toInt()],
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                reservedSize: 40,
                interval: (maxYBars / 4)
                    .ceilToDouble()
                    .clamp(1.0, maxYBars > 0 ? maxYBars : 1.0),
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade300, width: 1)),
          minY: 0,
          maxY: maxYBars,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey.shade800.withOpacity(0.9),
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${statuses[group.x]}\n',
                  const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  children: <TextSpan>[
                    TextSpan(
                      text: rod.toY.toInt().toString(),
                      style: TextStyle(
                        color: statusColors[statuses[group.x]],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 13, color: Colors.grey.shade800)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tempColor = Colors.red.shade400;
    final humColor = Colors.blue.shade400;
    final gasColor = Colors.green.shade500;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildChartCard(context, 'Tren Sensor (Suhu, Kelembaban, Gas)',
              Icons.timeline_rounded, _buildLineChart(context),
              legends: [
                _buildLegend(context, tempColor, 'Suhu'),
                _buildLegend(context, humColor, 'Kelembaban'),
                _buildLegend(context, gasColor, 'Gas'),
              ]),
          const SizedBox(height: 20),
          _buildChartCard(context, 'Distribusi Status Deteksi',
              Icons.pie_chart_outline_rounded, _buildBarChart(context)),
        ],
      ),
    );
  }
}

// --- RISK INFO PAGE ---
class RiskInfoPage extends StatelessWidget {
  const RiskInfoPage({super.key});

  Widget _buildRiskInfoCard(BuildContext context, String status,
      String description, String action, Color statusColor, IconData icon) {
    return Card(
      elevation: Theme.of(context).cardTheme.elevation ?? 4,
      margin: const EdgeInsets.symmetric(
          vertical: 10.0), // Increased vertical margin
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: statusColor, size: 32), // Larger icon
                const SizedBox(width: 12),
                Text(status.toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5)),
              ],
            ),
            Divider(
                height: 24,
                thickness: 1,
                color: Colors.grey.shade200), // Thicker divider
            _buildInfoSection(context, 'Deskripsi Risiko:', description),
            const SizedBox(height: 12),
            _buildInfoSection(
                context, 'Tindakan yang Direkomendasikan:', action),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                )),
        const SizedBox(height: 6),
        Text(content,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Panduan Tingkat Risiko Kebakaran",
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Pahami setiap level status untuk tindakan yang tepat.",
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _buildRiskInfoCard(
            context,
            'AMAN',
            'Kondisi lingkungan terpantau normal. Tidak ada indikasi langsung adanya bahaya kebakaran. Sensor suhu, kelembaban, dan gas berada dalam batas aman.',
            'Lakukan monitoring secara berkala. Pastikan semua peralatan deteksi berfungsi dengan baik. Tidak ada tindakan darurat yang diperlukan saat ini.',
            Colors.green.shade600,
            Icons.shield_rounded,
          ),
          _buildRiskInfoCard(
            context,
            'WASPADA',
            'Terdeteksi adanya potensi risiko kebakaran. Satu atau lebih parameter sensor (suhu meningkat, gas terdeteksi di atas ambang normal) menunjukkan anomali yang perlu perhatian.',
            'Segera lakukan pengecekan visual di area sekitar sensor. Identifikasi sumber potensi bahaya (misalnya, peralatan listrik yang panas, kebocoran gas ringan). Siapkan alat pemadam api ringan. Tingkatkan kewaspadaan.',
            Colors.orange.shade700,
            Icons.warning_amber_rounded,
          ),
          _buildRiskInfoCard(
            context,
            'BAHAYA',
            'Indikasi kuat adanya bahaya kebakaran yang signifikan dan mendesak. Sensor mendeteksi kondisi ekstrem (suhu sangat tinggi, konsentrasi gas berbahaya tinggi, atau deteksi api langsung oleh IR).',
            'SEGERA AKTIFKAN ALARM MANUAL JIKA PERLU! Lakukan evakuasi penghuni dari area terdampak melalui jalur evakuasi aman. Hubungi pemadam kebakaran (113 atau nomor darurat lokal). Jangan mencoba memadamkan api besar sendirian jika tidak terlatih.',
            Colors.red.shade700,
            Icons.dangerous_rounded,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.2))),
            child: Text(
              "PENTING: Panduan ini bersifat referensi. Selalu utamakan keselamatan jiwa dan ikuti prosedur darurat yang telah ditetapkan di lokasi Anda.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.9)),
            ),
          ),
        ],
      ),
    );
  }
}