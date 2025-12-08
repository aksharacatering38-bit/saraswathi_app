import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../models/menu_item.dart';

class MenuService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Live stream of menu items from Supabase
  Stream<List<MenuItemModel>> watchMenuItems() {
    final stream = _client
        .from('menu_items')
        .stream(primaryKey: ['id'])
        .order('category')
        .order('name');

    return stream.map(
      (rows) => rows.map((row) => MenuItemModel.fromMap(row)).toList(),
    );
  }
}
