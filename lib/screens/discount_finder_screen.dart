import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

import '../models/discount.dart';
import '../services/json_discount_service.dart';


class DiscountFinderScreen extends StatefulWidget {
  const DiscountFinderScreen({super.key});

  @override
  State<DiscountFinderScreen> createState() => _DiscountFinderScreenState();
}

class _DiscountFinderScreenState extends State<DiscountFinderScreen> {
  final JsonDiscountService _discountService = JsonDiscountService();
  bool _isLoading = true;
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  String? _errorMessage;

  List<Discount> _allDiscounts = [];
  List<Discount> _filteredDiscounts = [];

  Bank? _selectedBank;
  CategoryDiscount? _selectedCategory;
  double _minDiscountValue = 0;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;


  @override
  void initState() {
    super.initState();
    _loadMapData();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    // ID del bloque de anuncios de PRUEBA para un banner en Android.
    // ¡Usa siempre los de prueba durante el desarrollo!
    String adUnitId;

    if (kReleaseMode) {
      if (Platform.isAndroid) {
        adUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX_PROD_ANDROID';
      } else if (Platform.isIOS) {
        adUnitId = 'ca-app-pub-9552343552775183/8187504751';
      } else {
        return;
      }
    } else {
      if (Platform.isAndroid) {
        adUnitId = 'ca-app-pub-3940256099942544/6300978111';
      } else if (Platform.isIOS) {
        adUnitId = 'ca-app-pub-3940256099942544/2934735716';
      } else {
        return;
      }
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        // Se llama cuando el anuncio se carga correctamente
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        // Se llama si la carga del anuncio falla
        onAdFailedToLoad: (ad, err) {
          print('Fallo al cargar el banner: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose(); // Muy importante liberar la memoria del anuncio
    super.dispose();
  }


// Define la ubicación por defecto como una constante en tu clase para fácil acceso
  final LatLng _defaultLocation = const LatLng(-34.9038, -56.1513); // Rivera y Soca

  Future<void> _loadMapData() async {
    LatLng position; // Variable para guardar la posición final (real o por defecto)

    try {
      // --- INTENTO DE OBTENER LA UBICACIÓN REAL ---
      print("[DEBUG] Intentando obtener la ubicación real del usuario...");
      Location location = Location();

      // 1. Verificar servicio
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) serviceEnabled = await location.requestService();
      if (!serviceEnabled) throw Exception('Servicio de ubicación deshabilitado.');

      // 2. Verificar permisos
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception('Permiso de ubicación denegado.');
        }
      }

      // 3. Obtener ubicación con timeout
      final locationData = await location.getLocation().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('El GPS no respondió a tiempo.'),
      );

      position = LatLng(locationData.latitude!, locationData.longitude!);
      print("[DEBUG] Ubicación real obtenida: $position");

    } catch (e) {
      // --- SI CUALQUIER PARTE DE LA OBTENCIÓN DE UBICACIÓN FALLA ---
      print("[DEBUG] Falló la obtención de ubicación: ${e.toString()}. Usando ubicación por defecto.");
      position = _defaultLocation; // Asigna la ubicación por defecto

      // Opcional pero recomendado: Muestra una notificación no intrusiva
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo obtener tu ubicación. Mostrando mapa desde Rivera y Soca.'),
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    // --- DESPUÉS DE OBTENER UNA UBICACIÓN (REAL O POR DEFECTO), CARGA LOS DESCUENTOS ---
    // Este bloque ahora se ejecuta siempre.
    try {
      print("[DEBUG] Cargando descuentos...");
      final discounts = await _discountService.loadAllDiscounts();

      if (mounted) {
        setState(() {
          _currentPosition = position; // Usa la posición que se haya determinado
          _allDiscounts = discounts;
          _filteredDiscounts = discounts;
          _isLoading = false;
          _errorMessage = null; // Nos aseguramos de que no haya mensaje de error en la UI
        });
        print("[DEBUG] ¡Mapa y descuentos cargados!");
      }
    } catch (e) {
      // Este catch es por si falla la carga de los archivos JSON
      print("[DEBUG] ERROR CRÍTICO al cargar los descuentos: ${e.toString()}");
      if (mounted) {
        setState(() {
          _errorMessage = "No se pudieron cargar los comercios.";
          _isLoading = false;
          _currentPosition = _defaultLocation; // Aún así, muestra el mapa
        });
      }
    }
  }

  void _applyFilters() {
    List<Discount> filtered = _allDiscounts;

    if (_selectedBank != null) {
      filtered = filtered.where((d) => d.bank == _selectedBank).toList();
    }
    if (_selectedCategory != null) {
      filtered = filtered.where((d) => d.category == _selectedCategory).toList();
    }
    if (_minDiscountValue > 0) {
      filtered = filtered.where((d) => d.discountPercentage >= _minDiscountValue).toList();
    }

    setState(() {
      _filteredDiscounts = filtered;
    });
  }

  // --- CONSTRUCCIÓN DE LA INTERFAZ ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscador de Descuentos'),
        centerTitle: true,
      ),
      // Usamos un SafeArea para evitar que los elementos se superpongan con la UI del sistema (notch, etc.)
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: _isBannerAdLoaded
          ? SizedBox(
        height: _bannerAd!.size.height.toDouble(),
        width: _bannerAd!.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      )
          : const SizedBox(), // Si no está cargado, no muestra nada
    );
  }

  // En la clase _DiscountFinderScreenState

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: FlutterMap(
                mapController: _mapController, // Controlador asignado
                options: MapOptions(
                  initialCenter: _currentPosition!,
                  initialZoom: 14.0,
                  minZoom: 4,  // Zoom mínimo
                  maxZoom: 18, // Zoom máximo
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              ),
            ),
            _buildFilterPanel(),
          ],
        ),

        // --- WIDGETS DE ZOOM MANUALES ---
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(right: 10.0, top: 10.0),
            child: Align(
              alignment: Alignment.topRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // BOTÓN DE ACERCAR (+)
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    heroTag: "zoom-in-btn", // Tag único para el botón
                    onPressed: () {
                      // Llama al controlador para aumentar el zoom
                      final newZoom = _mapController.camera.zoom + 1;
                      _mapController.move(_mapController.camera.center, newZoom);
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  // BOTÓN DE ALEJAR (-)
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    heroTag: "zoom-out-btn", // Tag único para el botón
                    onPressed: () {
                      // Llama al controlador para disminuir el zoom
                      final newZoom = _mapController.camera.zoom - 1;
                      _mapController.move(_mapController.camera.center, newZoom);
                    },
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      // Usamos una decoración para darle un borde superior y distinguirlo del mapa
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<Bank>(
                  isExpanded: true,
                  value: _selectedBank,
                  hint: const Text("Banco"),
                  onChanged: (Bank? newValue) {
                    setState(() { _selectedBank = newValue; });
                    _applyFilters();
                  },
                  items: [
                    const DropdownMenuItem<Bank>(
                      value: null,
                      child: Text("Todos"),
                    ),
                    // Usamos "..." para añadir todos los items del enum
                    ...Bank.values.map((Bank bank) {
                      return DropdownMenuItem<Bank>(value: bank, child: Text(bank.name.toUpperCase()));
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButton<CategoryDiscount>(
                  isExpanded: true,
                  value: _selectedCategory,
                  hint: const Text("Categoría"),
                  onChanged: (CategoryDiscount? newValue) {
                    setState(() { _selectedCategory = newValue; });
                    _applyFilters();
                  },
                  items: [
                    const DropdownMenuItem<CategoryDiscount>(
                      value: null,
                      child: Text("Todas"),
                    ),
                    // Usamos "..." para añadir todos los items del enum
                    ...CategoryDiscount.values.map((CategoryDiscount cat) {
                      String categoryName = cat.name[0].toUpperCase() + cat.name.substring(1);
                      return DropdownMenuItem<CategoryDiscount>(
                        value: cat,
                        child: Text(categoryName),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text("Descuento mínimo: ${_minDiscountValue.toInt()}%"),
          Slider(
            value: _minDiscountValue,
            min: 0,
            max: 50,
            divisions: 5,
            label: "${_minDiscountValue.toInt()}%",
            onChanged: (double value) {
              setState(() { _minDiscountValue = value; });
            },
            onChangeEnd: (double value) {
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: _currentPosition!,
          width: 80,
          height: 80,
          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 50),
        ),
      );
    }

    for (final discount in _filteredDiscounts) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: discount.point,
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => DiscountInfoBottomSheet(discount: discount),
              );
            },
            child: DiscountMapMarker(discount: discount),
          ),
        ),
      );
    }
    return markers;
  }
}

// --- WIDGETS DE SOPORTE ---
// Los he mantenido aquí para que tengas todo el código en un solo lugar.

class DiscountMapMarker extends StatelessWidget {
  final Discount discount;
  const DiscountMapMarker({super.key, required this.discount});

  Color _getColorForBank(Bank bank) {
    switch (bank) {
      case Bank.itau: return Colors.orange;
      case Bank.scotia: return Colors.red;
      case Bank.brou: return Colors.green;
      case Bank.bbva: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _getColorForBank(discount.bank),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Center(
        child: Text(
          "${discount.discountPercentage}%",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
        ),
      ),
    );
  }
}

class DiscountInfoBottomSheet extends StatelessWidget {
  final Discount discount;
  const DiscountInfoBottomSheet({super.key, required this.discount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(discount.storeName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(discount.address, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Chip(
            label: Text("${discount.discountPercentage}% OFF con ${discount.bank.name.toUpperCase()}"),
            backgroundColor: Colors.teal.shade100,
          ),
          const SizedBox(height: 8),
          Text(discount.description),
        ],
      ),
    );
  }
}
