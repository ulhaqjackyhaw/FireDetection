import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:appmonitor/firebase_options.dart';
import 'package:lottie/lottie.dart';
import 'dart:typed_data';

// =========================================================================
// KODE INTI (TIDAK DIUBAH)
// Semua kode di bawah ini hingga 'main()' adalah bagian dari logika inti Anda
// yang tidak saya ubah sama sekali.
// =========================================================================

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

// Kelas model WaterPumpControl
class WaterPumpControl {
  final String state; // AUTO, ON, OFF
  final String currentStatus; // Current status description

  WaterPumpControl({
    required this.state,
    required this.currentStatus,
  });

  factory WaterPumpControl.fromMap(Map<dynamic, dynamic> map) {
    return WaterPumpControl(
      state: map['state'] ?? 'AUTO',
      currentStatus: map['current_status'] ?? 'AUTO (OFF)',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'state': state,
      'current_status': currentStatus,
    };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
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
          seedColor: const Color(0xFF3A506B),
          brightness: Brightness.light,
          primary: const Color(0xFF3A506B),
          secondary: const Color(0xFF1C7A71),
          surface: Colors.white,
          onSurface: const Color(0xFF333333),
          background: const Color(0xFFF0F4F8),
          onBackground: const Color(0xFF333333),
          error: const Color(0xFFD32F2F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3A506B),
          foregroundColor: Colors.white,
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
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          color: Colors.white,
          shadowColor: Colors.blueGrey.withOpacity(0.1),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222E3A)),
          titleLarge: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222E3A)),
          titleMedium: TextStyle(
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
          selectedItemColor: const Color(0xFF1C7A71),
          unselectedItemColor: Colors.blueGrey.shade300,
          elevation: 10,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3A506B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/intro.json',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
              repeat: false,
            ),
            const SizedBox(height: 32),
            const Text(
              'Fire Detection Monitoring',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Smart IoT Dashboard',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
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
  final DatabaseReference _pumpControlRef =
      FirebaseDatabase.instance.ref().child('water_pump_control');

  // Variabel untuk menyimpan data
  List<FireDetectionData> _historicalData = [];
  FireDetectionData? _latestData;
  WaterPumpControl? _waterPumpControl;

  // Konstanta
  static const int maxHistoricalData = 20;

  @override
  void initState() {
    super.initState();

    _databaseRef.onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value != null) {
        final data = FireDetectionData.fromMap(event.snapshot.value as Map);
        setState(() {
          _latestData = data;
          _updateHistoricalData(data);
        });
        _checkAndShowNotification(data);
      } else {
        setState(() => _latestData = null);
      }
    });

    _pumpControlRef.onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value != null) {
        final pumpData = WaterPumpControl.fromMap(event.snapshot.value as Map);
        setState(() => _waterPumpControl = pumpData);
      } else {
        setState(() => _waterPumpControl = null);
      }
    });
  }

  void _updateHistoricalData(FireDetectionData newData) {
    _historicalData.insert(0, newData);
    if (_historicalData.length > maxHistoricalData) {
      _historicalData = _historicalData.sublist(0, maxHistoricalData);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> _updateWaterPumpState(String newState) async {
    try {
      bool newPumpState = false;
      String currentStatus = '';

      if (newState == 'AUTO') {
        newPumpState = _latestData?.alarmActive == true;
        currentStatus = newPumpState ? 'AUTO (ON)' : 'AUTO (OFF)';
      } else if (newState == 'ON') {
        newPumpState = true;
        currentStatus = 'MANUAL (ON)';
      } else if (newState == 'OFF') {
        newPumpState = false;
        currentStatus = 'MANUAL (OFF)';
      }

      // Perubahan dari 'state': 'MANUAL_ON' atau 'MANUAL_OFF' menjadi 'ON' atau 'OFF'
      // agar konsisten dengan nilai yang dikirim dari UI.
      await _pumpControlRef.set({
        'state': newState,
        'current_status': currentStatus,
        'pump_on': newPumpState,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Water pump berhasil diubah ke mode $newState'),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengubah status water pump: $e'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }

  // =========================================================================
  // LOGIKA INTI (SELESAI)
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    // --- PERUBAHAN UI DIMULAI DI SINI ---
    // Menggunakan widget halaman yang sudah ditingkatkan (Enhanced)
    final List<Widget> pages = <Widget>[
      EnhancedDashboardPage(
        key: const PageStorageKey<String>('dashboardPage'),
        latestData: _latestData,
        waterPumpControl: _waterPumpControl,
        onUpdatePumpState: _updateWaterPumpState,
      ),
      EnhancedChartsPage(
        key: const PageStorageKey<String>('chartsPage'),
        historicalData: _historicalData,
      ),
      EnhancedWaterPumpControlPage(
        key: const PageStorageKey<String>('waterPumpPage'),
        waterPumpControl: _waterPumpControl,
        onUpdatePumpState: _updateWaterPumpState,
      ),
      const EnhancedRiskInfoPage(
        key: PageStorageKey<String>('riskInfoPage'),
      ),
    ];
    // --- AKHIR PERUBAHAN UI ---

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(_selectedIndex)),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded), label: 'Grafik'),
          BottomNavigationBarItem(
              icon: Icon(Icons.water_drop_rounded), label: 'Water Pump'),
          BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded), label: 'Info Risiko'),
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
        return 'Kontrol Water Pump';
      case 3:
        return 'Informasi Tingkat Risiko';
      default:
        return 'Monitoring Deteksi Api';
    }
  }

  void _checkAndShowNotification(FireDetectionData data) {
    String? notificationTitle;
    String? notificationBody;
    bool shouldNotify = false;

    if (data.fuzzyStatus == 'WASPADA') {
      notificationTitle = 'Peringatan: Status Waspada Terdeteksi!';
      notificationBody =
          'Tingkat bahaya: ${data.fuzzyDangerLevel.toStringAsFixed(1)}%. Suhu: ${data.temperature.toStringAsFixed(1)}°C, Gas: ${data.gas} ppm. Harap periksa kondisi sekitar.';
      shouldNotify = true;
    } else if (data.fuzzyStatus == 'BAHAYA') {
      notificationTitle = '🚨 DARURAT: STATUS BAHAYA TERDETEKSI! 🚨';
      notificationBody =
          'Tingkat bahaya SANGAT TINGGI: ${data.fuzzyDangerLevel.toStringAsFixed(1)}%. SEGERA LAKUKAN EVAKUASI dan hubungi pihak berwenang!';
      shouldNotify = true;
    }

    if (shouldNotify) {
      _showNotification(notificationTitle ?? '', notificationBody ?? '');
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const String customSoundName = 'alarm_kebakaran';
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
      sound: const RawResourceAndroidNotificationSound(customSoundName),
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
}

// =========================================================================
// WIDGET HALAMAN DENGAN UI YANG DITINGKATKAN
// Semua kode di bawah ini adalah UI baru yang lebih baik.
// =========================================================================

// --- ENHANCED DASHBOARD PAGE ---
class EnhancedDashboardPage extends StatelessWidget {
  final FireDetectionData? latestData;
  final WaterPumpControl? waterPumpControl;
  final Function(String) onUpdatePumpState;

  const EnhancedDashboardPage({
    super.key,
    required this.latestData,
    required this.waterPumpControl,
    required this.onUpdatePumpState,
  });

  @override
  Widget build(BuildContext context) {
    final data = latestData;
    if (data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
                color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 20),
            Text('Menunggu data dari sensor...',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusHeader(context, data),
          const SizedBox(height: 20),
          _buildSensorGrid(context, data),
          const SizedBox(height: 12),
          _buildWaterPumpControlCard(context),
          const SizedBox(height: 12),
          _buildInfoCard(context),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, FireDetectionData data) {
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
      elevation: 4,
      shadowColor: statusColor.withOpacity(0.3),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [statusColor.withOpacity(0.8), statusColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Status Keseluruhan',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Text(
                  data.fuzzyStatus,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Level Bahaya: ${data.fuzzyDangerLevel.toStringAsFixed(1)}%',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Update: ${DateFormat('HH:mm:ss').format(data.timestamp)}',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid(BuildContext context, FireDetectionData data) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildSensorTile(context, Icons.thermostat_rounded, 'Suhu',
            '${data.temperature.toStringAsFixed(1)} °C', Colors.red.shade400),
        _buildSensorTile(context, Icons.water_drop_outlined, 'Kelembaban',
            '${data.humidity.toStringAsFixed(1)} %', Colors.blue.shade400),
        _buildSensorTile(context, Icons.cloud_outlined, 'Kadar Gas',
            '${data.gas} ppm', Colors.green.shade400),
        _buildSensorTile(
          context,
          data.irDetectedFire
              ? Icons.local_fire_department
              : Icons.visibility_off_rounded,
          'Deteksi IR',
          data.irDetectedFire ? 'TERDETEKSI' : 'AMAN',
          data.irDetectedFire ? Colors.red.shade700 : Colors.grey.shade600,
        ),
      ],
    );
  }

  Widget _buildSensorTile(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium),
                Icon(icon, color: color, size: 24),
              ],
            ),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: color, fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterPumpControlCard(BuildContext context) {
    final pump = waterPumpControl;
    if (pump == null) {
      return const Card(
          child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Memuat data pompa...')));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop_rounded,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Kontrol Water Pump',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Text('Mode Saat Ini: ${pump.currentStatus}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            // Menggunakan SegmentedButton untuk UI yang lebih modern
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                      value: 'OFF',
                      label: Text('OFF'),
                      icon: Icon(Icons.power_off_rounded)),
                  ButtonSegment<String>(
                      value: 'AUTO',
                      label: Text('AUTO'),
                      icon: Icon(Icons.autorenew_rounded)),
                  ButtonSegment<String>(
                      value: 'ON',
                      label: Text('ON'),
                      icon: Icon(Icons.power_settings_new_rounded)),
                ],
                selected: {pump.state},
                onSelectionChanged: (Set<String> newSelection) {
                  onUpdatePumpState(newSelection.first);
                },
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade700,
                  selectedBackgroundColor:
                      Theme.of(context).colorScheme.primary,
                  selectedForegroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Theme.of(context).colorScheme.primary, size: 32),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Gunakan tab di bawah untuk melihat grafik historis, mengontrol pompa air, dan melihat info risiko.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- ENHANCED CHARTS PAGE ---
class EnhancedChartsPage extends StatelessWidget {
  final List<FireDetectionData> historicalData;
  const EnhancedChartsPage({super.key, required this.historicalData});

  @override
  Widget build(BuildContext context) {
    if (historicalData.isEmpty) {
      return const Center(child: Text('Belum ada data historis untuk grafik'));
    }
    final reversedData = historicalData.reversed.toList();
    final avgTemp =
        reversedData.map((e) => e.temperature).reduce((a, b) => a + b) /
            reversedData.length;
    final avgHum = reversedData.map((e) => e.humidity).reduce((a, b) => a + b) /
        reversedData.length;
    final avgGas =
        reversedData.map((e) => e.gas.toDouble()).reduce((a, b) => a + b) /
            reversedData.length;

    // Pie chart data
    final statusCounts = <String, int>{'AMAN': 0, 'WASPADA': 0, 'BAHAYA': 0};
    for (var d in reversedData) {
      if (statusCounts.containsKey(d.fuzzyStatus)) {
        statusCounts[d.fuzzyStatus] = statusCounts[d.fuzzyStatus]! + 1;
      }
    }

    // AI: Prediksi status mengikuti fuzzyStatus terakhir dari Firebase
    String predStatus = historicalData.first.fuzzyStatus;
    double confidence = (statusCounts[predStatus]! / reversedData.length) * 100;
    String aiAdvice = '';
    if (predStatus == 'BAHAYA') {
      aiAdvice = 'BAHAYA! Segera lakukan evakuasi dan hubungi pihak berwenang.';
    } else if (predStatus == 'WASPADA') {
      aiAdvice = 'Tingkat waspada! Periksa area sekitar sensor dan siapkan tindakan pencegahan.';
    } else if (predStatus == 'AMAN') {
      aiAdvice = 'Lingkungan aman. Tetap pantau secara berkala.';
    } else {
      aiAdvice = 'Status tidak diketahui. Periksa sistem sensor.';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Menampilkan ${historicalData.length} data terakhir',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text('AI Prediksi & Saran',
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Prediksi status berikutnya: ',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Row(
                    children: [
                      Icon(
                        predStatus == 'BAHAYA'
                            ? Icons.dangerous_rounded
                            : predStatus == 'WASPADA'
                                ? Icons.warning_amber_rounded
                                : Icons.shield_rounded,
                        color: predStatus == 'BAHAYA'
                            ? Colors.red.shade700
                            : predStatus == 'WASPADA'
                                ? Colors.orange.shade700
                                : Colors.green.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        predStatus,
                        style: TextStyle(
                          color: predStatus == 'BAHAYA'
                              ? Colors.red.shade700
                              : predStatus == 'WASPADA'
                                  ? Colors.orange.shade700
                                  : Colors.green.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Confidence: ${confidence.toStringAsFixed(0)}%',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Saran AI:',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(aiAdvice,
                      style: const TextStyle(
                          fontSize: 14, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildSensorLineChart(
            context,
            'Suhu (°C)',
            Colors.red.shade400,
            reversedData.map((e) => e.temperature).toList(),
          ),
          const SizedBox(height: 16),
          _buildSensorLineChart(
            context,
            'Kelembaban (%)',
            Colors.blue.shade400,
            reversedData.map((e) => e.humidity).toList(),
          ),
          const SizedBox(height: 16),
          _buildSensorLineChart(
            context,
            'Kadar Gas (ppm)',
            Colors.green.shade400,
            reversedData.map((e) => e.gas.toDouble()).toList(),
          ),
          const SizedBox(height: 24),
          Text('Rata-rata Sensor (Bar Chart)',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    [avgTemp, avgHum, avgGas].reduce((a, b) => a > b ? a : b) +
                        10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Text('Suhu');
                          case 1:
                            return const Text('Kelembaban');
                          case 2:
                            return const Text('Gas');
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(
                        toY: avgTemp, color: Colors.red.shade400, width: 24)
                  ]),
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(
                        toY: avgHum, color: Colors.blue.shade400, width: 24)
                  ]),
                  BarChartGroupData(x: 2, barRods: [
                    BarChartRodData(
                        toY: avgGas, color: Colors.green.shade400, width: 24)
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Proporsi Status Fuzzy (Pie Chart)',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: statusCounts['AMAN']!.toDouble(),
                    color: Colors.green.shade600,
                    title: 'AMAN\n${statusCounts['AMAN']}',
                    radius: 50,
                    titleStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: statusCounts['WASPADA']!.toDouble(),
                    color: Colors.orange.shade700,
                    title: 'WASPADA\n${statusCounts['WASPADA']}',
                    radius: 50,
                    titleStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: statusCounts['BAHAYA']!.toDouble(),
                    color: Colors.red.shade700,
                    title: 'BAHAYA\n${statusCounts['BAHAYA']}',
                    radius: 50,
                    titleStyle: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorLineChart(
      BuildContext context, String title, Color color, List<double> values) {
    final spots =
        List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                          color: Colors.grey.shade200, strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(value.toInt().toString(),
                                style: const TextStyle(fontSize: 12));
                          }),
                    ),
                    bottomTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.2),
                      ),
                    ),
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

// --- ENHANCED WATER PUMP CONTROL PAGE ---
class EnhancedWaterPumpControlPage extends StatelessWidget {
  final WaterPumpControl? waterPumpControl;
  final Function(String) onUpdatePumpState;

  const EnhancedWaterPumpControlPage({
    super.key,
    required this.waterPumpControl,
    required this.onUpdatePumpState,
  });

  @override
  Widget build(BuildContext context) {
    final pump = waterPumpControl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Lottie.asset(
            'assets/water.json', // Anda perlu menambahkan aset Lottie ini
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 16),
          Text(
            'Pilih Mode Operasi Pompa',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Kontrol pompa air secara manual atau biarkan sistem bekerja otomatis.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (pump == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildControlCard(
              context,
              'AUTO',
              'Mode Otomatis',
              'Sistem akan menyalakan pompa jika terdeteksi bahaya.',
              Theme.of(context).colorScheme.primary,
              Icons.autorenew_rounded,
              isSelected: pump.state == 'AUTO',
            ),
            const SizedBox(height: 12),
            _buildControlCard(
              context,
              'ON',
              'Manual ON',
              'Paksa pompa untuk menyala sekarang.',
              Colors.blue.shade600,
              Icons.power_settings_new_rounded,
              isSelected: pump.state == 'ON',
            ),
            const SizedBox(height: 12),
            _buildControlCard(
              context,
              'OFF',
              'Manual OFF',
              'Paksa pompa untuk mati sekarang.',
              Colors.red.shade600,
              Icons.power_off_rounded,
              isSelected: pump.state == 'OFF',
            ),
            const SizedBox(height: 24),
            _buildCurrentStatus(context, pump),
          ],
        ],
      ),
    );
  }

  Widget _buildControlCard(BuildContext context, String mode, String title,
      String description, Color color, IconData icon,
      {bool isSelected = false}) {
    return Card(
      elevation: isSelected ? 6 : 2,
      shadowColor:
          isSelected ? color.withOpacity(0.4) : Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: color, width: 2)
            : BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onUpdatePumpState(mode),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: color)),
                    const SizedBox(height: 6),
                    Text(description,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: color, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStatus(BuildContext context, WaterPumpControl pump) {
    final bool isOn = pump.currentStatus.contains('ON');
    final Color statusColor =
        isOn ? Colors.blue.shade600 : Colors.grey.shade700;
    final IconData statusIcon =
        isOn ? Icons.water_drop_rounded : Icons.water_drop_outlined;

    return Card(
      color: statusColor.withOpacity(0.1),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, color: statusColor, size: 28),
            const SizedBox(width: 12),
            Text('Status Saat Ini:',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Text(
              pump.currentStatus,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: statusColor),
            )
          ],
        ),
      ),
    );
  }
}

// --- ENHANCED RISK INFO PAGE ---
class EnhancedRiskInfoPage extends StatelessWidget {
  const EnhancedRiskInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> riskLevels = [
      {
        'status': 'AMAN',
        'range': '0 - 30%',
        'description':
            'Kondisi normal. Tidak ada potensi kebakaran. Tetap pantau secara berkala.',
        'action': 'Tidak perlu tindakan khusus. Pastikan sistem tetap aktif dan pantau secara berkala.',
        'color': Colors.green.shade600,
        'icon': Icons.shield_rounded
      },
      {
        'status': 'WASPADA',
        'range': '31 - 70%',
        'description':
            'Peningkatan suhu/gas terdeteksi. Periksa area sekitar sensor dan siapkan tindakan pencegahan.',
        'action': 'Lakukan pengecekan area sekitar sensor. Siapkan alat pemadam dan pastikan jalur evakuasi aman.',
        'color': Colors.orange.shade700,
        'icon': Icons.warning_amber_rounded
      },
      {
        'status': 'BAHAYA',
        'range': '71 - 100%',
        'description':
            'Potensi kebakaran sangat tinggi! Alarm aktif. Segera evakuasi dan hubungi pihak berwenang.',
        'action': 'Segera lakukan evakuasi! Hubungi petugas keamanan atau pemadam kebakaran. Jika IR mendeteksi api, tindakan harus lebih cepat.',
        'color': Colors.red.shade700,
        'icon': Icons.dangerous_rounded
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: riskLevels.length,
      itemBuilder: (context, index) {
        final level = riskLevels[index];
        return _buildRiskInfoCard(
          context,
          level['status'],
          level['range'],
          level['description'],
          level['action'],
          level['color'],
          level['icon'],
        );
      },
    );
  }

  Widget _buildRiskInfoCard(BuildContext context, String status, String range,
      String description, String action, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 28),
                        const SizedBox(width: 12),
                        Text(status,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: color)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Level Bahaya: $range',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tindakan:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      action,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                    ),
                    if (status == 'BAHAYA') ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.red, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Jika deteksi api oleh sensor IR, status otomatis BAHAYA dan tindakan harus segera dilakukan!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red.shade400, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ]
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