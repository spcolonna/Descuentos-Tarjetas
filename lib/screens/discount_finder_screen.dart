import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

import '../enums/Bank.dart';
import '../enums/CardTier.dart';
import '../enums/CategoryDiscount.dart';
import '../models/discount.dart';
import '../services/json_discount_service.dart';
import '../widgets/DiscountInfoBottomSheet.dart';
import '../widgets/DiscountMapMarker.dart';


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
  CardTier? _selectedCardTier;
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
        adUnitId = 'ca-app-pub-9552343552775183/7317141133';
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
      print("[DEBUG] Service is enable: $serviceEnabled");
      if (!serviceEnabled) serviceEnabled = await location.requestService();
      print("[DEBUG] Service is enable 2: $serviceEnabled");
      if (!serviceEnabled) throw Exception('Servicio de ubicación deshabilitado.');

      // 2. Verificar permisos
      PermissionStatus permissionGranted = await location.hasPermission();
      print("[DEBUG] Permission Status: $permissionGranted");
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        print("[DEBUG] Permission Status 2: $permissionGranted");
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

    filtered = filtered.where((discount) {
      return discount.discounts.any((tier) {
        final bool tierMatches = _selectedCardTier == null || tier.tier == _selectedCardTier;
        final bool valueMatches = tier.value >= _minDiscountValue;
        return tierMatches && valueMatches;
      });
    }).toList();

    setState(() {
      _filteredDiscounts = filtered;
    });
  }

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

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentPosition!,
                  initialZoom: 13.0,
                ),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0, top: 10.0),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        FloatingActionButton(
                          mini: true, heroTag: "zoom-in-btn",
                          onPressed: () { _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1); },
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          mini: true, heroTag: "zoom-out-btn",
                          onPressed: () { _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1); },
                          child: const Icon(Icons.remove),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildFilterPanel(),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers = [];
    if (_currentPosition != null) {
      markers.add(Marker(point: _currentPosition!, child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 50)));
    }
    for (final discount in _filteredDiscounts) {
      markers.add(
        Marker(
          width: 40, height: 40,
          point: discount.point,
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) => DiscountInfoBottomSheet(discount: discount),
              );
            },
            child: DiscountMapMarker(
              discount: discount,
              selectedCardTier: _selectedCardTier,
            ),
          ),
        ),
      );
    }
    return markers;
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
              Expanded(child: _buildBankFilter()),
              const SizedBox(width: 12),
              Expanded(child: _buildCategoryFilter()),
            ],
          ),
          const SizedBox(height: 8),
          _buildCardTierFilter(),
          const SizedBox(height: 8),
          _buildDiscountSlider(),
        ],
      ),
    );
  }

  Widget _buildBankFilter() {
    return DropdownButton<Bank?>(
      isExpanded: true,
      value: _selectedBank,
      hint: const Text("Todos los Bancos"),
      onChanged: (Bank? newValue) {
        setState(() { _selectedBank = newValue; });
        _applyFilters();
      },
      items: [
        const DropdownMenuItem<Bank?>(value: null, child: Text("Todos los Bancos")),
        ...Bank.values.map((bank) {
          String bankName = bank.name[0].toUpperCase() + bank.name.substring(1);
          return DropdownMenuItem<Bank>(value: bank, child: Text(bankName));
        }).toList(),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return DropdownButton<CategoryDiscount?>(
      isExpanded: true,
      value: _selectedCategory,
      hint: const Text("Categoría"),
      onChanged: (CategoryDiscount? newValue) {
        setState(() { _selectedCategory = newValue; });
        _applyFilters();
      },
      items: const [
        DropdownMenuItem<CategoryDiscount?>(value: null, child: Text("Todas")),
        DropdownMenuItem<CategoryDiscount?>(value: CategoryDiscount.gastronomia, child: Text("Gastronomía")),
        DropdownMenuItem<CategoryDiscount?>(value: CategoryDiscount.librerias, child: Text("Librería")),
        DropdownMenuItem<CategoryDiscount?>(value: CategoryDiscount.otro, child: Text("Otros")),
      ],
    );
  }

// MÉTODO NUEVO PARA EL FILTRO DE TIPO DE TARJETA
  Widget _buildCardTierFilter() {
    return DropdownButton<CardTier?>(
      isExpanded: true,
      value: _selectedCardTier,
      hint: const Text("Todo tipo de Tarjeta"),
      onChanged: (CardTier? newValue) {
        setState(() { _selectedCardTier = newValue; });
        _applyFilters();
      },
      items: const [
        DropdownMenuItem<CardTier?>(value: null, child: Text("Todas (Común y Premium)")),
        DropdownMenuItem<CardTier?>(value: CardTier.basic, child: Text("Común")),
        DropdownMenuItem<CardTier?>(value: CardTier.premium, child: Text("Premium")),
      ],
    );
  }

  Widget _buildDiscountSlider() {
    return Column(
      children: [
        Text("Descuento mínimo: ${_minDiscountValue.toInt()}%"),
        Slider(
          value: _minDiscountValue,
          min: 0,
          max: 50,
          divisions: 10,
          label: "${_minDiscountValue.toInt()}%",
          onChanged: (double value) {
            setState(() { _minDiscountValue = value; });
          },
          onChangeEnd: (double value) {
            _applyFilters();
          },
        ),
      ],
    );
  }
}
