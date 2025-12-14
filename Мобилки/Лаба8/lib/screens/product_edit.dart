import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/product.dart';

class ProductEditPage extends StatefulWidget { //экран добавления/редактирования товара
  final String? productId; //если null, значит мы создаём новый продукт; если задан — редактируем существующий
  const ProductEditPage({super.key, this.productId});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _reviewsCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();

  late Box productsBox;
  Product? editing; //локальная переменная, в которой хранится загруженный Product

  @override
  void initState() {
    super.initState();
    productsBox = Hive.box('products');
    if (widget.productId != null) {
      editing = productsBox.get(widget.productId) as Product?;
      if (editing != null) { //наполняем контроллеры текущими значениями
        _descCtrl.text = editing!.description;
        _locCtrl.text = editing!.location;
        _priceCtrl.text = editing!.price.toString();
        _reviewsCtrl.text = editing!.reviewsCount.toString();
        _imageCtrl.text = editing!.imagePath;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.productId == null ? 'Add Offer' : 'Edit Offer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), validator: (v) => v == null || v.isEmpty ? 'Required' : null,),
              TextFormField(controller: _locCtrl, decoration: const InputDecoration(labelText: 'Location')),
              TextFormField(controller: _priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price (USD)')),
              TextFormField(controller: _reviewsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Reviews count')),
              TextFormField(controller: _imageCtrl, decoration: const InputDecoration(labelText: 'Image asset path')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async { //Кнопка "Save"
                  if (!_formKey.currentState!.validate()) return;
                  final id = editing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
                  final product = Product(
                    id: id,
                    imagePath: _imageCtrl.text,
                    price: double.tryParse(_priceCtrl.text) ?? 0.0,
                    location: _locCtrl.text,
                    reviewsCount: int.tryParse(_reviewsCtrl.text) ?? 0,
                    description: _descCtrl.text,
                    isLiked: editing?.isLiked ?? false,
                  );
                  await productsBox.put(id, product); //сохраняем
                  if (!mounted) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.pop(context);
                  });
                },
                child: const Text('Save'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
