import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddItemScreen extends StatefulWidget {
  final Map<String, dynamic>? existingItem;

  const AddItemScreen({super.key, this.existingItem});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _itemTypeController = TextEditingController();

  bool isAvailable = true;
  bool isBestSeller = false;

  File? _imageFile;
  String? existingImageUrl;

  final picker = ImagePicker();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _nameController.text = item['name'] ?? '';
      _descriptionController.text = item['description'] ?? '';
      _priceController.text = item['price']?.toString() ?? '';
      _categoryController.text = item['category'] ?? '';
      _itemTypeController.text = item['item_type'] ?? '';
      isAvailable = item['is_available'] ?? true;
      isBestSeller = item['is_best_seller'] ?? false;
      existingImageUrl = item['image_url'];
    }
  }

  Future pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<String?> uploadImage(String id) async {
    if (_imageFile == null) {
      return existingImageUrl; 
    }

    final fileExt = _imageFile!.path.split('.').last;
    final fileName = "$id.$fileExt";

    final storagePath = 'items/$fileName';

    await supabase.storage
        .from('item-images')
        .upload(storagePath, _imageFile!, fileOptions: const FileOptions(upsert: true));

    return supabase.storage.from('item-images').getPublicUrl(storagePath);
  }

  Future saveItem() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final category = _categoryController.text.trim();
    final itemType = _itemTypeController.text.trim();

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Price required")),
      );
      return;
    }

    String id = widget.existingItem?['id'] ?? supabase.functions.uuid();

    final imageUrl = await uploadImage(id);

    final data = {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'item_type': itemType,
      'is_available': isAvailable,
      'is_best_seller': isBestSeller,
      'image_url': imageUrl,
    };

    if (widget.existingItem == null) {
      await supabase.from('menu_items').insert(data);
    } else {
      await supabase.from('menu_items').update(data).eq('id', id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Item saved successfully")),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingItem == null ? "Add Item" : "Edit Item"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                color: Colors.grey[300],
                child: _imageFile != null
                    ? Image.file(_imageFile!, fit: BoxFit.cover)
                    : (existingImageUrl != null
                        ? Image.network(existingImageUrl!, fit: BoxFit.cover)
                        : const Icon(Icons.add_a_photo, size: 50)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: "Description")),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price")),
            TextField(controller: _categoryController, decoration: const InputDecoration(labelText: "Category")),
            TextField(controller: _itemTypeController, decoration: const InputDecoration(labelText: "Item Type")),
            SwitchListTile(
              title: const Text("Available"),
              value: isAvailable,
              onChanged: (v) => setState(() => isAvailable = v),
            ),
            SwitchListTile(
              title: const Text("Best Seller"),
              value: isBestSeller,
              onChanged: (v) => setState(() => isBestSeller = v),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveItem,
              child: Text(widget.existingItem == null ? "Add Item" : "Update Item"),
            )
          ],
        ),
      ),
    );
  }
}
