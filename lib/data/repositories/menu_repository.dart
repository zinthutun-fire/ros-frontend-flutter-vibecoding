import '../models/menu_item_model.dart';

abstract class MenuRepository {
  Future<List<MenuItemModel>> getMenuItems();
}
