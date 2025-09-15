import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  // 🔹 ahora son listas para multi-select
  List<Bank> _selectedBanks = [];
  List<CategoryDiscount> _selectedCategories = [];
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
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('Fallo al cargar el banner: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  final LatLng _defaultLocation =
  const LatLng(-34.9038, -56.1513); // Rivera y Soca

  Future<void> _loadMapData() async {
    LatLng position;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permiso de ubicación denegado por el usuario.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Permiso de ubicación denegado permanentemente. Habilítalo en los ajustes del teléfono.');
      }

      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
              'No se pudo obtener la ubicación en 15 segundos.');
        },
      );

      position = LatLng(currentPosition.latitude, currentPosition.longitude);
    } catch (e) {
      print("[DEBUG] Falló la obtención de ubicación: $e");
      position = _defaultLocation;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    try {
      final discounts = await _discountService.loadAllDiscounts();

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _allDiscounts = discounts;
          _filteredDiscounts = discounts;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "No se pudieron cargar los comercios.";
          _isLoading = false;
          _currentPosition = _defaultLocation;
        });
      }
    }
  }

  void _applyFilters() {
    List<Discount> filtered = _allDiscounts;

    if (_selectedBanks.isNotEmpty) {
      filtered =
          filtered.where((d) => _selectedBanks.contains(d.bank)).toList();
    }

    if (_selectedCategories.isNotEmpty) {
      filtered =
          filtered.where((d) => _selectedCategories.contains(d.category)).toList();
    }

    filtered = filtered.where((discount) {
      return discount.discounts.any((tier) {
        final bool tierMatches =
            _selectedCardTier == null || tier.tier == _selectedCardTier;
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
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: _isBannerAdLoaded
          ? SizedBox(
        height: _bannerAd!.size.height.toDouble(),
        width: _bannerAd!.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      )
          : const SizedBox(),
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
                  initialZoom: 16, // 🔹 zoom inicial más grande
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.descuentos_uy',
                  ),
                  MarkerLayer(
                    markers: _buildMarkers(),
                  ),
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
                          mini: true,
                          heroTag: "zoom-in-btn",
                          onPressed: () {
                            _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom + 1);
                          },
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton(
                          mini: true,
                          heroTag: "zoom-out-btn",
                          onPressed: () {
                            _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom - 1);
                          },
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
      markers.add(Marker(
          point: _currentPosition!,
          child: const Icon(Icons.person_pin_circle,
              color: Colors.blue, size: 50)));
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
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20))),
                builder: (context) =>
                    DiscountInfoBottomSheet(discount: discount),
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
    return ElevatedButton(
      onPressed: () async {
        final result = await showDialog<List<Bank>>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text("Seleccionar Bancos"),
              content: StatefulBuilder(
                builder: (ctx, setStateDialog) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: Bank.values.map((bank) {
                        return CheckboxListTile(
                          title: Text(bank.name[0].toUpperCase() +
                              bank.name.substring(1)),
                          value: _selectedBanks.contains(bank),
                          onChanged: (checked) {
                            setStateDialog(() {
                              if (checked == true) {
                                _selectedBanks.add(bank);
                              } else {
                                _selectedBanks.remove(bank);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    child: const Text("Cancelar")),
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, _selectedBanks),
                    child: const Text("Aceptar")),
              ],
            );
          },
        );

        if (result != null) {
          setState(() {
            _selectedBanks = result;
          });
          _applyFilters();
        }
      },
      child: Text(_selectedBanks.isEmpty
          ? "Todos los Bancos"
          : "${_selectedBanks.length} bancos"),
    );
  }

  Widget _buildCategoryFilter() {
    return ElevatedButton(
      onPressed: () async {
        final result = await showDialog<List<CategoryDiscount>>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text("Seleccionar Categorías"),
              content: StatefulBuilder(
                builder: (ctx, setStateDialog) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: CategoryDiscount.values.map((cat) {
                        return CheckboxListTile(
                          title: Text(cat.name[0].toUpperCase() +
                              cat.name.substring(1)),
                          value: _selectedCategories.contains(cat),
                          onChanged: (checked) {
                            setStateDialog(() {
                              if (checked == true) {
                                _selectedCategories.add(cat);
                              } else {
                                _selectedCategories.remove(cat);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    child: const Text("Cancelar")),
                ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, _selectedCategories),
                    child: const Text("Aceptar")),
              ],
            );
          },
        );

        if (result != null) {
          setState(() {
            _selectedCategories = result;
          });
          _applyFilters();
        }
      },
      child: Text(_selectedCategories.isEmpty
          ? "Todas las Categorías"
          : "${_selectedCategories.length} categorías"),
    );
  }

  Widget _buildCardTierFilter() {
    return DropdownButton<CardTier?>(
      isExpanded: true,
      value: _selectedCardTier,
      hint: const Text("Todo tipo de Tarjeta"),
      onChanged: (CardTier? newValue) {
        setState(() {
          _selectedCardTier = newValue;
        });
        _applyFilters();
      },
      items: const [
        DropdownMenuItem<CardTier?>(
            value: null, child: Text("Todas (Común y Premium)")),
        DropdownMenuItem<CardTier?>(value: CardTier.basic, child: Text("Común")),
        DropdownMenuItem<CardTier?>(
            value: CardTier.premium, child: Text("Premium")),
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
            setState(() {
              _minDiscountValue = value;
            });
          },
          onChangeEnd: (double value) {
            _applyFilters();
          },
        ),
      ],
    );
  }
}
