import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';

class ProductEditPage extends StatefulWidget {
  final String? productId;
  const ProductEditPage({super.key, this.productId});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _flightNumberCtrl = TextEditingController();
  final _depCityCtrl = TextEditingController();
  final _arrCityCtrl = TextEditingController();
  final _depTimeCtrl = TextEditingController();
  final _arrTimeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController();
  final _airlineCtrl = TextEditingController();

  Flight? editing;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      final flightsProvider = context.read<FlightsProvider>(); //получаем данные провайдера
      editing = flightsProvider.getFlightById(widget.productId!);
      if (editing != null) {
        _flightNumberCtrl.text = editing!.flightNumber;
        _depCityCtrl.text = editing!.departureCity;
        _arrCityCtrl.text = editing!.arrivalCity;
        _depTimeCtrl.text = editing!.departureTime;
        _arrTimeCtrl.text = editing!.arrivalTime;
        _priceCtrl.text = editing!.price.toString();
        _seatsCtrl.text = editing!.availableSeats.toString();
        _airlineCtrl.text = editing!.airline;
      }
    }
  }

  @override
  void dispose() {
    _flightNumberCtrl.dispose();
    _depCityCtrl.dispose();
    _arrCityCtrl.dispose();
    _depTimeCtrl.dispose();
    _arrTimeCtrl.dispose();
    _priceCtrl.dispose();
    _seatsCtrl.dispose();
    _airlineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Add Flight' : 'Edit Flight'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _flightNumberCtrl,
                decoration: const InputDecoration(labelText: 'Flight Number'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _depCityCtrl,
                decoration: const InputDecoration(labelText: 'Departure City'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _arrCityCtrl,
                decoration: const InputDecoration(labelText: 'Arrival City'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _depTimeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Departure Time (HH:MM)',
                  hintText: '10:30',
                ),
              ),
              TextFormField(
                controller: _arrTimeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Arrival Time (HH:MM)',
                  hintText: '14:15',
                ),
              ),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (USD)'),
              ),
              TextFormField(
                controller: _seatsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Available Seats'),
              ),
              TextFormField(
                controller: _airlineCtrl,
                decoration: const InputDecoration(labelText: 'Airline'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;

                  final id = editing?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString();
                  final flight = Flight(
                    id: id,
                    flightNumber: _flightNumberCtrl.text,
                    departureCity: _depCityCtrl.text,
                    arrivalCity: _arrCityCtrl.text,
                    departureTime: _depTimeCtrl.text,
                    arrivalTime: _arrTimeCtrl.text,
                    price: double.tryParse(_priceCtrl.text) ?? 0.0,
                    availableSeats: int.tryParse(_seatsCtrl.text) ?? 0,
                    airline: _airlineCtrl.text,
                    isLiked: editing?.isLiked ?? false,
                  );

                  //сохранение через провайдер
                  final flightsProvider = context.read<FlightsProvider>();
                  if (editing != null) {
                    flightsProvider.updateFlight(flight);
                  } else {
                    flightsProvider.addFlight(flight);
                  }

                  Navigator.pop(context);
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
