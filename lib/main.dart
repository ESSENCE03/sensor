// --------------------------- 1) import 문 (파일 최상단) ---------------------------
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

// Firebase 옵션 (각자 환경에 맞게)
import 'firebase_options_server2.dart';
import 'firebase_options_server3.dart';

// --------------------------- 2) regionMap + 매핑/함수 선언 ---------------------------

// “앞바다” 지역 목록 (총 27개)
final Map<String, String> regionMap = {
  // 기존 유지 2개
  "서해남부앞바다": "12A30100",
  "남해동부앞바다": "12B20100",

  // 추가 25개
  "인천·경기남부앞바다": "12A20102",
  "경기북부앞바다": "12A20101",
  "부산앞바다": "12B20103",
  "울산앞바다": "12C10101",
  "경남중부남해앞바다": "12B20102",
  "경남서부남해앞바다": "12B20101",
  "거제시동부앞바다": "12B20104",
  "경북남부앞바다": "12C10102",
  "경북북부앞바다": "12C10103",
  "전남북부서해앞바다": "22A30103",
  "전남중부서해앞바다": "22A30104",
  "전남남부서해앞바다": "22A30105",
  "전남서부남해앞바다": "12B10101",
  "전남동부남해앞바다": "12B10102",
  "전북북부앞바다": "22A30101",
  "전북남부앞바다": "22A30102",
  "충남북부앞바다": "12A20103",
  "충남남부앞바다": "12A20104",
  "강원북부앞바다": "12C20103",
  "강원중부앞바다": "12C20102",
  "강원남부앞바다": "12C20101",
  "제주도북부앞바다": "12B10302",
  "제주도남부앞바다": "12B10303",
  "제주도동부앞바다": "12B10301",
  "제주도서부앞바다": "12B10304",
};

// 날씨 코드 매핑
final Map<String, String> wfCdMapping = {
  'DB01': '맑음',
  'DB03': '구름 많음',
  'DB04': '흐림',
};

// 바람 추세 매핑
final Map<String, String> wdTndMapping = {
  '1': '바람 약해짐',
  '2': '바람 강해짐',
};

// "yyyyMMddHHmm" → "yy년 MM월 DD일 HH:MM"
String formatUpdateTime(String rawTime) {
  try {
    if (rawTime.length < 12) return rawTime;
    final year = rawTime.substring(2, 4);
    final month = rawTime.substring(4, 6);
    final day = rawTime.substring(6, 8);
    final hour = rawTime.substring(8, 10);
    final min = rawTime.substring(10, 12);

    return '$year년 $month월 $day일 $hour:$min';
  } catch (e) {
    debugPrint('Time Formatting Error: $e');
    return 'Invalid Time';
  }
}

// --------------------------- 3) WeatherData 모델 ---------------------------
class WeatherData {
  final String windDirection1;
  final String windDirection2;
  final String windSpeed1;
  final String windSpeed2;
  final String waveHeight1;
  final String waveHeight2;
  final String weatherForecastCode;
  final String precipitationType;
  final String weather;
  final String windTrend;
  final String updateTime;

  WeatherData({
    required this.windDirection1,
    required this.windDirection2,
    required this.windSpeed1,
    required this.windSpeed2,
    required this.waveHeight1,
    required this.waveHeight2,
    required this.weatherForecastCode,
    required this.precipitationType,
    required this.weather,
    required this.windTrend,
    required this.updateTime,
  });

  factory WeatherData.fromXML(XmlDocument document) {
    final items = document.findAllElements('item');
    final item = items.isNotEmpty ? items.first : null;

    final tmFcElement = document.findAllElements('tmFc').isNotEmpty
        ? document.findAllElements('tmFc').first
        : null;
    final updateTimeRaw = tmFcElement != null ? tmFcElement.text.trim() : 'N/A';

    String getItemText(XmlElement? parent, String tagName) {
      if (parent == null) return 'N/A';
      return parent
          .findElements(tagName)
          .map((e) => e.text.trim())
          .firstWhere((_) => true, orElse: () => 'N/A');
    }

    return WeatherData(
      windDirection1: getItemText(item, 'wd1'),
      windDirection2: getItemText(item, 'wd2'),
      windSpeed1: getItemText(item, 'ws1'),
      windSpeed2: getItemText(item, 'ws2'),
      waveHeight1: getItemText(item, 'wh1'),
      waveHeight2: getItemText(item, 'wh2'),
      weatherForecastCode: getItemText(item, 'wfCd'),
      precipitationType: getItemText(item, 'rnYn'),
      weather: getItemText(item, 'wf'),
      windTrend: getItemText(item, 'wdTnd'),
      updateTime: updateTimeRaw,
    );
  }
}

// --------------------------- 4) 날씨 API 호출 (regId 동적) ---------------------------
Future<WeatherData> fetchWeatherData(String regId) async {
  const String baseUrl =
      "http://apis.data.go.kr/1360000/VilageFcstMsgService/getSeaFcst";

  final Map<String, String> queryParams = {
    'serviceKey':
    'wy61abWR4Q7GNLnrESJX5PIMmqn4r2GKDO8QgX1VP7qmgQ2/sTYCpB46ncC6PMY3FdcNr5agXkToDtVGx0prtA==',
    'numOfRows': '10',
    'dataType': 'XML',
    'pageNo': '1',
    'regId': regId, // <-- 동적으로 설정
  };

  final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

  try {
    final response = await http.get(uri);
    debugPrint('날씨 API 응답: ${response.statusCode}');
    debugPrint(response.body);

    if (response.statusCode == 200) {
      final document = XmlDocument.parse(response.body);
      return WeatherData.fromXML(document);
    } else {
      throw Exception('날씨 API 에러: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('날씨 API 통신 에러: $e');
  }
}

// --------------------------- 5) Firebase 초기화 + main() ---------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      name: 'server2',
      options: FirebaseOptionsServer2.currentPlatform,
    );
    await Firebase.initializeApp(
      name: 'server3',
      options: FirebaseOptionsServer3.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase 초기화 오류: $e');
    // 오류를 적절히 처리 (예: 다이얼로그 표시, 재시도 로직 등)
  }

  runApp(const MyApp());
}

// --------------------------- 6) MyApp ---------------------------
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const Color primaryColor = Color(0xFF0277BD);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '해상 풍력 모니터링',
      theme: ThemeData(
        primaryColor: primaryColor,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        fontFamily: 'Roboto',
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          centerTitle: true,
        ),
        useMaterial3: true,
      ),
      home: const RealTimeDataScreen(),
    );
  }
}

// --------------------------- 7) RealTimeDataScreen ---------------------------
class RealTimeDataScreen extends StatefulWidget {
  const RealTimeDataScreen({Key? key}) : super(key: key);

  @override
  _RealTimeDataScreenState createState() => _RealTimeDataScreenState();
}

class _RealTimeDataScreenState extends State<RealTimeDataScreen> {
  final DatabaseReference _server2Ref =
  FirebaseDatabase.instanceFor(app: Firebase.app('server2')).ref('results');
  final DatabaseReference _server3Ref =
  FirebaseDatabase.instanceFor(app: Firebase.app('server3')).ref('results');

  // 센서 데이터 맵
  Map<String, dynamic> _server2Data = {
    '온도': 0.0,
    '발전출력(mW)': 0.0,
    '풍향(°)': 0.0,
    '기어박스 소음(dB)': 0.0,
    '블레이드 소음(dB)': 0.0,
    '화염 감지': 'None',
    '진동(g)': 0.0,
    'K202': 0.0, // 필요한 경우 초기화
  };

  bool _isGearboxSoundAbnormal = false;
  bool _isVibrationAbnormal = false;
  String _abnormalSensorName = '';

  // 서버3 갱신 시간
  String _timestamp = '';

  // 서버2 갱신 시간 (이미 "hh:mm:ss" 형식)
  String _server2Timestamp = '';

  // 날씨 데이터
  WeatherData? _currentWeatherData;
  bool _isLoadingWeather = true;
  String? _weatherError;

  // 지역 선택 (총 27개 앞바다 중 하나)
  String _selectedRegionName = "서해남부앞바다";

  Timer? _weatherTimer;

  // regId 가져오기
  String get _selectedRegId => regionMap[_selectedRegionName] ?? "12A30100";

  // 긴급 메시지 표시 여부 추적 플래그
  bool _emergencyDialogShown = false;

  @override
  void initState() {
    super.initState();
    _initializeFirebaseListeners();
    _fetchAndSetWeatherData();
    // 일정 주기로 (60초) 날씨 재호출
    _weatherTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _fetchAndSetWeatherData();
    });
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    super.dispose();
  }

  void _initializeFirebaseListeners() {
    // ------------------ 서버2 (센서 데이터) ------------------
    _server2Ref.onValue.listen((DatabaseEvent event) {
      final rawData = event.snapshot.value;
      if (rawData != null) {
        try {
          final dataMap =
          Map<String, dynamic>.from(rawData as Map<dynamic, dynamic>);
          setState(() {
            // 1) 센서값 파싱
            _server2Data = _processServer2Data(dataMap);

            // 2) 서버2 timestamp (이미 "hh:mm:ss" 형식)
            _server2Timestamp = dataMap['timestamp']?.toString() ?? 'N/A';
            debugPrint('Received server2Timestamp: $_server2Timestamp');
          });
          _checkAbnormalState();
        } catch (e) {
          debugPrint('Server 2 파싱 오류: $e');
        }
      }
    }, onError: (error) {
      debugPrint('Server 2 오류: $error');
    });

    // ------------------ 서버3 (이상 상태) ------------------
    _server3Ref.onValue.listen((DatabaseEvent event) {
      final rawData = event.snapshot.value;
      if (rawData != null) {
        try {
          final dataMap =
          Map<String, dynamic>.from(rawData as Map<dynamic, dynamic>);
          setState(() {
            // faultStatus를 기반으로 진동 이상 상태 설정
            _isVibrationAbnormal = (dataMap['faultStatus'] ?? 0) == 1;

            _isGearboxSoundAbnormal =
                (dataMap['gearboxSound']?['status'] ?? 0) == 1;
            _timestamp = dataMap['timestamp'] ?? '';
            debugPrint('Received server3 faultStatus: ${dataMap['faultStatus']}');
            debugPrint('_isVibrationAbnormal: $_isVibrationAbnormal');
            debugPrint('_isGearboxSoundAbnormal: $_isGearboxSoundAbnormal');
          });
          _checkAbnormalState();
        } catch (e) {
          debugPrint('Server 3 파싱 오류: $e');
        }
      }
    }, onError: (error) {
      debugPrint('Server 3 오류: $error');
    });
  }

  Map<String, dynamic> _processServer2Data(Map<String, dynamic> dataMap) {
    return {
      '온도': _parseDouble(dataMap['temperature']),
      '발전출력(mW)': _parseDouble(dataMap['power_mW']),
      '풍향(°)': _parseDouble(dataMap['windDirection']),
      '기어박스 소음(dB)': _parseDouble(dataMap['gearboxSound']),
      '블레이드 소음(dB)': _parseDouble(dataMap['bladeSound']),
      '화염 감지': dataMap['flameStatus']?.toString() ?? 'None',
      '진동(g)': _parseDouble(dataMap['rmsVibration']),
      'K202': _parseDouble(dataMap['K202']), // K202 처리
    };
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // 날씨 재호출 (사용자 선택 지역의 regId)
  Future<void> _fetchAndSetWeatherData() async {
    setState(() {
      _isLoadingWeather = true;
      _weatherError = null;
    });
    try {
      final wData = await fetchWeatherData(_selectedRegId);
      setState(() {
        _currentWeatherData = wData;
        _isLoadingWeather = false;
      });
    } catch (e) {
      setState(() {
        _weatherError = '날씨 로드 에러: $e';
        _isLoadingWeather = false;
      });
    }
  }

  void _checkAbnormalState() {
    List<String> abnormalSensors = [];

    if (_isGearboxSoundAbnormal) {
      abnormalSensors.add('기어박스 소음');
    }
    if (_isVibrationAbnormal) {
      abnormalSensors.add('진동 센서');
    }
    if (_server2Data['화염 감지'] != 'None') {
      abnormalSensors.add('화염 감지');
    }

    if (abnormalSensors.isNotEmpty) {
      _abnormalSensorName = abnormalSensors.join(', ');
      debugPrint('Abnormal Sensors: $_abnormalSensorName');
    } else {
      _abnormalSensorName = '';
    }

    // 긴급 메시지 표시 로직
    if (_isAbnormal && !_emergencyDialogShown) {
      _showEmergencyDialog(abnormalSensors);
    } else if (!_isAbnormal) {
      _emergencyDialogShown = false;
    }
  }

  bool get _isAbnormal =>
      _isGearboxSoundAbnormal ||
          _isVibrationAbnormal ||
          _server2Data['화염 감지'] != 'None';

  // 긴급 메시지 AlertDialog 표시 함수
  void _showEmergencyDialog(List<String> abnormalSensors) {
    _emergencyDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: false, // 사용자가 대화 상자를 닫을 수 없도록 설정
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '긴급 알림',
            style: TextStyle(color: Colors.red),
          ),
          content: Text(
            abnormalSensors.isNotEmpty
                ? abnormalSensors.map((sensor) => '$sensor 센서에서 이상이 감지되었습니다').join('\n')
                : '이상 상태가 감지되었습니다.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                '확인',
                style: TextStyle(color: Colors.blue),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('해상 풍력 모니터링'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchAndSetWeatherData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 1) 지역 선택 Dropdown
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildRegionDropdown(),
                ),
                const SizedBox(height: 16),

                // 2) 기상 정보 섹션
                _buildWeatherSection(context),
                const SizedBox(height: 16),

                // 3) 상태 박스 (현재 상태 + 갱신 시간)
                _buildStatusBox(context),
                const SizedBox(height: 16),

                // 소음 카드
                _buildSoundCardSplitBox(
                  gearboxValue: _server2Data['기어박스 소음(dB)'] as double,
                  bladeValue: _server2Data['블레이드 소음(dB)'] as double,
                  isGearboxAbnormal: _isGearboxSoundAbnormal,
                  isBladeAbnormal: false,
                ),
                const SizedBox(height: 16),

                // 센서 Grid
                _buildSensorGrid(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),

      // 이상 감지 FAB
      floatingActionButton: _isAbnormal
          ? FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            _abnormalSensorName = '';
            _emergencyDialogShown = false;
          });
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.warning, color: Colors.white),
        label: Text(
          _abnormalSensorName.isNotEmpty
              ? '이상 감지: $_abnormalSensorName'
              : '이상 감지',
          style: const TextStyle(color: Colors.white),
        ),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Dropdown: 지역 선택
  Widget _buildRegionDropdown() {
    return DropdownButton<String>(
      value: _selectedRegionName,
      items: regionMap.keys.map((regionName) {
        return DropdownMenuItem(
          value: regionName,
          child: Text(regionName, style: const TextStyle(fontSize: 16)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedRegionName = newValue;
          });
          // 지역 변경 시 날씨 재호출
          _fetchAndSetWeatherData();
        }
      },
    );
  }

  // 상태 박스 (현재 상태 + 갱신 시간)
  Widget _buildStatusBox(BuildContext context) {
    // 서버2 timestamp는 이미 "hh:mm:ss" 형식
    final displayTimestamp = _server2Timestamp;

    return Card(
      child: ListTile(
        leading: Icon(
          _isAbnormal ? Icons.warning : Icons.check_circle,
          size: 36,
          color: _isAbnormal ? Colors.red : Colors.green,
        ),
        title: Text(
          _isAbnormal ? '현재 상태: 이상 발생' : '현재 상태: 정상',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _isAbnormal ? Colors.red : Colors.green,
          ),
        ),
        subtitle: displayTimestamp == 'N/A' || displayTimestamp.isEmpty
            ? const Text(
          '갱신 시간: 알 수 없음',
          style: TextStyle(color: Colors.red),
        )
            : Text(
          '갱신 시간: $displayTimestamp',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  // 기상정보 섹션
  Widget _buildWeatherSection(BuildContext context) {
    if (_isLoadingWeather) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_weatherError != null) {
      return Text(_weatherError!, style: const TextStyle(color: Colors.red));
    }
    if (_currentWeatherData == null) {
      return const Text('날씨 데이터가 없습니다');
    }

    final data = _currentWeatherData!;
    final formattedTime = formatUpdateTime(data.updateTime);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단: "기상 정보" + 갱신 시간
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.sailing, size: 24, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      '기상 정보',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  formattedTime,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // (행1) 풍속1/풍속2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherItem(Icons.air, '풍속1', '${data.windSpeed1} m/s'),
                _buildWeatherItem(
                    Icons.air_outlined, '풍속2', '${data.windSpeed2} m/s'),
              ],
            ),
            const SizedBox(height: 16),

            // (행2) 파고1/파고2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherItem(Icons.water, '파고1', '${data.waveHeight1} m'),
                _buildWeatherItem(
                    Icons.water_drop, '파고2', '${data.waveHeight2} m'),
              ],
            ),
            const SizedBox(height: 16),

            // (행3) 날씨 / 바람 추세
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWeatherItem(
                  Icons.cloud,
                  '날씨',
                  wfCdMapping[data.weatherForecastCode] ?? data.weather,
                ),
                _buildWeatherItem(
                  Icons.change_circle,
                  '바람 추세',
                  wdTndMapping[data.windTrend] ?? data.windTrend,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: Colors.blueGrey),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  // 소음 카드
  Widget _buildSoundCardSplitBox({
    required double gearboxValue,
    required double bladeValue,
    required bool isGearboxAbnormal,
    required bool isBladeAbnormal,
  }) {
    final isSoundAbnormal = isGearboxAbnormal || isBladeAbnormal;
    final cardColor = isSoundAbnormal ? Colors.red[50] : Colors.blue[50];

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 기어박스
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up,
                    size: 28,
                    color: isGearboxAbnormal ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '기어박스 소음',
                    style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${gearboxValue.toStringAsFixed(1)} dB',
                    style: TextStyle(
                      fontSize: 14,
                      color: isGearboxAbnormal ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              height: 60,
              width: 1,
              color: Colors.grey.shade300,
            ),
            // 블레이드
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up,
                    size: 28,
                    color: isBladeAbnormal ? Colors.red : Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '블레이드 소음',
                    style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${bladeValue.toStringAsFixed(1)} dB',
                    style: TextStyle(
                      fontSize: 14,
                      color: isBladeAbnormal ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 센서 Grid
  Widget _buildSensorGrid() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2 / 2.5,
      ),
      children: [
        _buildSensorCard(
            '온도', _server2Data['온도'], '°C', Icons.thermostat),
        _buildSensorCard('발전출력', _server2Data['발전출력(mW)'], 'mW',
            Icons.flash_on),
        _buildSensorCard(
            '풍향', _server2Data['풍향(°)'], '°', Icons.explore),
        _buildSensorCard(
          '화염 감지',
          _server2Data['화염 감지'],
          '',
          Icons.local_fire_department,
          isAbnormal: _server2Data['화염 감지'] != 'None',
        ),
        _buildSensorCard(
          '진동',
          _server2Data['진동(g)'],
          'g',
          Icons.vibration,
          isAbnormal: _isVibrationAbnormal,
          // 진동(g) 센서는 소수점 이하 4자리 표시
          decimalPlaces: 4, // <-- 추가된 부분
        ),
        _buildSensorCard('K202', _server2Data['K202'], '',
            Icons.handyman),
      ],
    );
  }

  // --------------------------- _buildSensorCard 수정 ---------------------------
  Widget _buildSensorCard(
      String title, dynamic value, String unit, IconData icon,
      {bool isAbnormal = false, int decimalPlaces = 2}) { // <-- decimalPlaces 매개변수 추가
    String displayValue;
    if (value is double) {
      displayValue = value.toStringAsFixed(decimalPlaces); // 소수점 이하 자릿수 적용
    } else {
      displayValue = value.toString();
    }

    final cardColor = isAbnormal ? Colors.red[50] : Colors.white;
    final textColor = isAbnormal ? Colors.red : Colors.black;

    return Card(
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isAbnormal ? Colors.red : Colors.blue),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 6),
            Text(
              unit.isNotEmpty ? '$displayValue $unit' : displayValue,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}
