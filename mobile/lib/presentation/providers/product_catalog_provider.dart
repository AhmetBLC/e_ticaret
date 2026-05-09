import 'package:flutter/foundation.dart';

import '../../core/debug/app_debug_log.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/pagination_model.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';

class ProductCatalogProvider extends ChangeNotifier {
  ProductCatalogProvider(this._repository);

  final ProductRepository _repository;

  final List<ProductModel> _products = [];
  PaginationModel? _pagination;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  static const _pageSize = 20;

  String? _query;
  String? _categoryId;
  String? _city;

  List<ProductModel> get products => List.unmodifiable(_products);
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  String? get query => _query;
  String? get categoryId => _categoryId;
  String? get city => _city;

  bool get hasMore =>
      _pagination != null && _page < _pagination!.totalPages;

  void setFilters({String? query, String? categoryId, String? city}) {
    _query = query;
    _categoryId = categoryId;
    _city = city;
    refresh();
  }

  Future<void> refresh() async {
    _page = 1;
    _products.clear();
    _pagination = null;
    await loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    if (_loading) {
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    appDebugLog('Catalog', 'loadFirstPage.start', 'q=$_query cat=$_categoryId city=$_city');
    try {
      final result = await _repository.getProducts(
        page: 1, 
        limit: _pageSize,
        query: _query,
        categoryId: _categoryId,
        city: _city,
      );
      _products
        ..clear()
        ..addAll(result.products);
      _pagination = result.pagination;
      _page = 1;
      appDebugLog(
        'Catalog',
        'loadFirstPage.done',
        'count=${_products.length} total=${_pagination?.total}',
      );
    } on ApiException catch (e) {
      appDebugLog('Catalog', 'loadFirstPage.api_error', e.message);
      _error = e.message;
    } catch (e, st) {
      appDebugError('Catalog', e, st, 'loadFirstPage');
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore) {
      return;
    }
    _loadingMore = true;
    notifyListeners();
    try {
      final next = _page + 1;
      appDebugLog('Catalog', 'loadMore', 'page=$next q=$_query');
      final result = await _repository.getProducts(
        page: next, 
        limit: _pageSize,
        query: _query,
        categoryId: _categoryId,
        city: _city,
      );
      _products.addAll(result.products);
      _pagination = result.pagination;
      _page = next;
      appDebugLog('Catalog', 'loadMore.done', 'totalItems=${_products.length}');
    } on ApiException catch (e) {
      appDebugLog('Catalog', 'loadMore.api_error', e.message);
      _error = e.message;
    } catch (e, st) {
      appDebugError('Catalog', e, st, 'loadMore');
      _error = e.toString();
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
