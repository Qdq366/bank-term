import 'package:dio/dio.dart';

/// 后端接口封装（免登录，无 Token 拦截）
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      // Android 模拟器访问宿主机；真机调试请改为电脑局域网 IP
      baseUrl: 'http://10.0.2.2:3000/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  dynamic _unwrap(Response res) {
    final body = res.data;
    if (body is Map<String, dynamic>) {
      if (body['code'] == 200) return body['data'];
      throw Exception(body['message'] ?? '请求失败');
    }
    return body;
  }

  String _errMsg(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (e.type == DioExceptionType.connectionError) {
      return '无法连接服务器，请确认后端已启动';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return '网络超时，请检查后端服务';
    }
    return '网络异常，请稍后重试';
  }

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) async {
    try {
      return _unwrap(await _dio.get(path, queryParameters: query));
    } on DioException catch (e) {
      throw Exception(_errMsg(e));
    }
  }

  Future<dynamic> _post(String path, {dynamic data}) async {
    try {
      return _unwrap(await _dio.post(path, data: data));
    } on DioException catch (e) {
      throw Exception(_errMsg(e));
    }
  }

  Future<dynamic> _put(String path, {dynamic data}) async {
    try {
      return _unwrap(await _dio.put(path, data: data));
    } on DioException catch (e) {
      throw Exception(_errMsg(e));
    }
  }

  Future<dynamic> _delete(String path) async {
    try {
      return _unwrap(await _dio.delete(path));
    } on DioException catch (e) {
      throw Exception(_errMsg(e));
    }
  }

  /* ---------- 分类 ---------- */
  Future<dynamic> getCategoryTree() => _get('/categories/tree');
  Future<dynamic> createCategory(String name, String? parentId) =>
      _post('/categories', data: {'name': name, 'parentId': parentId});
  Future<dynamic> renameCategory(String id, String name) =>
      _put('/categories/$id', data: {'name': name});
  Future<dynamic> deleteCategory(String id) => _delete('/categories/$id');

  /* ---------- 笔记 ---------- */
  /// page=0 表示返回全部（长文档阅读用）
  Future<dynamic> getNotes({String? categoryId, String? keyword, bool? important}) {
    final query = <String, dynamic>{'page': 0};
    if (categoryId != null && categoryId.isNotEmpty) query['categoryId'] = categoryId;
    if (keyword != null && keyword.trim().isNotEmpty) query['keyword'] = keyword.trim();
    if (important == true) query['important'] = 'true';
    return _get('/notes', query: query);
  }

  Future<dynamic> createNote(Map<String, dynamic> payload) => _post('/notes', data: payload);
  Future<dynamic> updateNote(String id, Map<String, dynamic> payload) =>
      _put('/notes/$id', data: payload);
  Future<dynamic> deleteNote(String id) => _delete('/notes/$id');
}
