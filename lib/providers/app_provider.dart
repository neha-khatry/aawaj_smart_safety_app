import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/contact.dart';
import '../models/recording.dart';

class AppProvider extends ChangeNotifier {
  // ===================== AUTH (JWT) =====================
  String? _accessToken;
  String? get accessToken => _accessToken;
  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;

  // ===================== USER =====================
  String _userName = 'User';
  String get userName => _userName;

  // ===================== CONTACTS =====================
  List<EmergencyContact> _contacts = [];
  List<EmergencyContact> get contacts => _contacts;

  // ===================== RECORDINGS =====================
  List<Recording> _recordings = [];
  List<Recording> get recordings => _recordings;

  // ===================== SETTINGS =====================
  bool _voiceActivation = true;
  bool _shakeDetection = false;
  bool _powerButton = true;
  bool _disguiseMode = false;
  bool _liveTracking = true;
  bool _smsAlerts = true;
  bool _offlineRecording = true;
  bool _checkInEnabled = false;

  bool get voiceActivation => _voiceActivation;
  bool get shakeDetection => _shakeDetection;
  bool get powerButton => _powerButton;
  bool get disguiseMode => _disguiseMode;
  bool get liveTracking => _liveTracking;
  bool get smsAlerts => _smsAlerts;
  bool get offlineRecording => _offlineRecording;
  bool get checkInEnabled => _checkInEnabled;

  // ===================== LOCATION =====================
  double? _latitude;
  double? _longitude;
  String _locationStatus = 'Fetching location...';

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String get locationStatus => _locationStatus;

  // ===================== RECORDING STATE =====================
  bool _isRecording = false;
  String _recordingType = '';
  int _recordingSeconds = 0;

  bool get isRecording => _isRecording;
  String get recordingType => _recordingType;
  int get recordingSeconds => _recordingSeconds;

  // ===================== SOS STATE =====================
  bool _sosActive = false;
  int _sosCountdown = 10;

  bool get sosActive => _sosActive;
  int get sosCountdown => _sosCountdown;

  AppProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Auth token
    _accessToken = prefs.getString('accessToken');

    // User
    _userName = prefs.getString('userName') ?? 'User';

    // Settings
    _voiceActivation = prefs.getBool('voiceActivation') ?? true;
    _shakeDetection = prefs.getBool('shakeDetection') ?? false;
    _powerButton = prefs.getBool('powerButton') ?? true;
    _smsAlerts = prefs.getBool('smsAlerts') ?? true;
    _offlineRecording = prefs.getBool('offlineRecording') ?? true;
    _checkInEnabled = prefs.getBool('checkInEnabled') ?? false;

    // Contacts
    final contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      final List<dynamic> decoded = json.decode(contactsJson);
      _contacts = decoded.map((e) => EmergencyContact.fromJson(e)).toList();
    }

    // Recordings
    final recordingsJson = prefs.getString('recordings');
    if (recordingsJson != null) {
      final List<dynamic> decoded = json.decode(recordingsJson);
      _recordings = decoded.map((e) => Recording.fromJson(e)).toList();
    }

    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();

    // Auth token
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      await prefs.setString('accessToken', _accessToken!);
    } else {
      await prefs.remove('accessToken');
    }

    // User + settings
    await prefs.setString('userName', _userName);
    await prefs.setBool('voiceActivation', _voiceActivation);
    await prefs.setBool('shakeDetection', _shakeDetection);
    await prefs.setBool('powerButton', _powerButton);
    await prefs.setBool('smsAlerts', _smsAlerts);
    await prefs.setBool('offlineRecording', _offlineRecording);
    await prefs.setBool('checkInEnabled', _checkInEnabled);

    // Contacts + recordings
    await prefs.setString(
      'contacts',
      json.encode(_contacts.map((e) => e.toJson()).toList()),
    );
    await prefs.setString(
      'recordings',
      json.encode(_recordings.map((e) => e.toJson()).toList()),
    );
  }

  // ===================== AUTH METHODS =====================
  Future<void> setAccessToken(String token) async {
    _accessToken = token;
    await _saveData();
    notifyListeners();
  }

  Future<void> logout() async {
    _accessToken = null;
    await _saveData();
    notifyListeners();
  }

  // ===================== USER METHODS =====================
  void setUserName(String name) {
    _userName = name;
    _saveData();
    notifyListeners();
  }

  // ===================== CONTACT METHODS =====================
  void addContact(EmergencyContact contact) {
    _contacts.add(contact);
    _saveData();
    notifyListeners();
  }

  void removeContact(String id) {
    _contacts.removeWhere((c) => c.id == id);
    _saveData();
    notifyListeners();
  }

  // ===================== RECORDING METHODS =====================
  void addRecording(Recording recording) {
    _recordings.insert(0, recording);
    _saveData();
    notifyListeners();
  }

  void setRecordingState(bool isRecording, String type) {
    _isRecording = isRecording;
    _recordingType = type;
    _recordingSeconds = 0;
    notifyListeners();
  }

  void updateRecordingTime(int seconds) {
    _recordingSeconds = seconds;
    notifyListeners();
  }

  // ===================== LOCATION METHODS =====================
  void updateLocation(double lat, double lng, String status) {
    _latitude = lat;
    _longitude = lng;
    _locationStatus = status;
    notifyListeners();
  }

  void setLocationStatus(String status) {
    _locationStatus = status;
    notifyListeners();
  }

  // ===================== SETTINGS METHODS =====================
  void toggleVoiceActivation() {
    _voiceActivation = !_voiceActivation;
    _saveData();
    notifyListeners();
  }

  void toggleShakeDetection() {
    _shakeDetection = !_shakeDetection;
    _saveData();
    notifyListeners();
  }

  void togglePowerButton() {
    _powerButton = !_powerButton;
    _saveData();
    notifyListeners();
  }

  void toggleDisguiseMode() {
    _disguiseMode = !_disguiseMode;
    notifyListeners();
  }

  void toggleLiveTracking() {
    _liveTracking = !_liveTracking;
    notifyListeners();
  }

  void toggleSmsAlerts() {
    _smsAlerts = !_smsAlerts;
    _saveData();
    notifyListeners();
  }

  void toggleOfflineRecording() {
    _offlineRecording = !_offlineRecording;
    _saveData();
    notifyListeners();
  }

  void toggleCheckIn() {
    _checkInEnabled = !_checkInEnabled;
    _saveData();
    notifyListeners();
  }

  // ===================== SOS METHODS =====================
  void activateSOS() {
    _sosActive = true;
    _sosCountdown = 10;
    notifyListeners();
  }

  void updateSOSCountdown(int value) {
    _sosCountdown = value;
    notifyListeners();
  }

  void cancelSOS() {
    _sosActive = false;
    _sosCountdown = 10;
    notifyListeners();
  }
}