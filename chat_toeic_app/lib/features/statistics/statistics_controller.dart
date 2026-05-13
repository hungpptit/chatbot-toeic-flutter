import 'package:get/get.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';

class StatisticsController extends GetxController {
  var isLoading = true.obs;
  var isChartLoading = false.obs;
  
  // Data from APIs
  var userStats = <String, dynamic>{}.obs;
  var partStats = <Map<String, dynamic>>[].obs;
  var accuracyOverTime = <Map<String, dynamic>>[].obs;
  var historyStats = <Map<String, dynamic>>[].obs;

  // Pagination for History
  var currentHistoryPage = 1.obs;
  var historyPageSize = 5.obs;

  // Timeframe for Accuracy Chart
  var selectedTimeframe = 30.obs; // Default 30 days

  @override
  void onInit() {
    super.onInit();
    fetchAllStats();
    
    // Khi đổi khoảng thời gian, gọi lại API biểu đồ
    ever(selectedTimeframe, (_) => fetchAccuracyStats());
  }

  Future<void> fetchAllStats() async {
    isLoading.value = true;
    try {
      final responses = await Future.wait([
        DioClient.dio.get('/v1/statistics/user-tests'),
        DioClient.dio.get('/v1/statistics/parts'),
        DioClient.dio.get('/v1/statistics/accuracy-over-time?days=${selectedTimeframe.value}'),
        DioClient.dio.get('/v1/statistics/user-test-history'),
      ]);

      if (responses[0].statusCode == 200) userStats.value = responses[0].data['data'] ?? {};
      if (responses[1].statusCode == 200) partStats.value = List<Map<String, dynamic>>.from(responses[1].data['data'] ?? []);
      if (responses[2].statusCode == 200) accuracyOverTime.value = List<Map<String, dynamic>>.from(responses[2].data['data'] ?? []);
      if (responses[3].statusCode == 200) historyStats.value = List<Map<String, dynamic>>.from(responses[3].data['data'] ?? []);
      
    } catch (e) {
      print('Error fetching statistics: $e');
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu thống kê');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAccuracyStats() async {
    isChartLoading.value = true;
    try {
      final response = await DioClient.dio.get('/v1/statistics/accuracy-over-time?days=${selectedTimeframe.value}');
      if (response.statusCode == 200) {
        accuracyOverTime.value = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
      }
    } catch (e) {
      print('Error fetching accuracy stats: $e');
    } finally {
      isChartLoading.value = false;
    }
  }

  // Getters for Pagination
  List<Map<String, dynamic>> get paginatedHistory {
    final startIndex = (currentHistoryPage.value - 1) * historyPageSize.value;
    final endIndex = startIndex + historyPageSize.value;
    
    if (startIndex >= historyStats.length) return [];
    return historyStats.sublist(
      startIndex, 
      endIndex > historyStats.length ? historyStats.length : endIndex
    );
  }

  int get totalHistoryPages {
    if (historyStats.isEmpty) return 0;
    return (historyStats.length / historyPageSize.value).ceil();
  }

  String formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0 phút';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '$hours giờ $minutes phút';
    }
    return '$minutes phút';
  }
}
