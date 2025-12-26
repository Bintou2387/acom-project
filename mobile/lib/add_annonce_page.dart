import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart'; 
import 'api_service.dart';
import 'annonce_model.dart';

class AddAnnoncePage extends StatefulWidget {
  final Annonce? annonceAModifier;

  const AddAnnoncePage({super.key, this.annonceAModifier});

  @override
  State<AddAnnoncePage> createState() => _AddAnnoncePageState();
}

class _AddAnnoncePageState extends State<AddAnnoncePage> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  bool _isLoading = false;
  
  // Images
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Position GPS (Par défaut Casablanca)
  double _latitude = 33.5731;
  double _longitude = -7.5898;
  bool _isLocating = false;
  bool _locationFound = false;

  String _category = 'AUTOMOBILE';
  String _selectedPeriod = 'jour'; // Par défaut
  String _transactionType = 'LOCATION'; // Par défaut

  // Contrôleurs
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  // Auto
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _modelCtrl = TextEditingController();
  final TextEditingController _kmCtrl = TextEditingController();
  final TextEditingController _yearCtrl = TextEditingController();
  String _fuelType = 'DIESEL';

  // Immo
  final TextEditingController _surfaceCtrl = TextEditingController();
  final TextEditingController _roomsCtrl = TextEditingController();
  String _immoType = 'APPARTEMENT';
  bool _hasPool = false;

  bool get isEditMode => widget.annonceAModifier != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _prefillData();
    }
  }

  void _prefillData() {
    final a = widget.annonceAModifier!;
    
    // Champs de base
    _titleCtrl.text = a.title;
    _priceCtrl.text = a.price.toString();
    _descCtrl.text = a.description;
    _phoneCtrl.text = a.phoneNumber ?? "";
    _category = a.category;
    _latitude = a.latitude;
    _longitude = a.longitude;
    _locationFound = true;

    // Champs Auto
    if (_category == 'AUTOMOBILE' && a.detailsAuto != null) {
      // CORRECTION ICI : Ajout du '!' pour forcer le type non-null
      final d = a.detailsAuto!; 
      _brandCtrl.text = d['brand'] ?? "";
      _modelCtrl.text = d['model'] ?? "";
      _yearCtrl.text = (d['year'] ?? "").toString();
      _kmCtrl.text = (d['mileage_km'] ?? "").toString();
      if (d['fuel_type'] != null) _fuelType = d['fuel_type'];
    }

    // Champs Immo
    if (_category == 'IMMOBILIER' && a.detailsImmo != null) {
      // CORRECTION ICI : Ajout du '!'
      final d = a.detailsImmo!;
      _surfaceCtrl.text = (d['surface_m2'] ?? "").toString();
      _roomsCtrl.text = (d['rooms_count'] ?? "").toString();
      if (d['type_bien'] != null) _immoType = d['type_bien'];
      _hasPool = d['has_pool'] ?? false;
    }
  }

  // --- FONCTION GPS ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le GPS est désactivé.")));
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Permission GPS refusée.")));
          setState(() => _isLocating = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationFound = true;
        _isLocating = false;
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Position trouvée !"), backgroundColor: Colors.green));

    } catch (e) {
      print("Erreur GPS: $e");
      setState(() => _isLocating = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de la localisation")));
    }
  }

  // --- FONCTIONS IMAGES ---
  Future<void> _pickFromGallery() async {
    final List<XFile> photos = await _picker.pickMultiImage();
    if (photos.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(photos.map((p) => File(p.path)).toList());
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImages.add(File(photo.path));
      });
    }
  }

  void _removeImage(File image) {
    setState(() {
      _selectedImages.remove(image);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? "Modifier l'annonce" : "Nouvelle Annonce"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ZONE PHOTOS (Masquée en mode édition)
            if (!isEditMode) ...[
              const Text("Photos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildAddButton(Icons.camera_alt, "Caméra", _pickFromCamera),
                    const SizedBox(width: 10),
                    _buildAddButton(Icons.photo_library, "Galerie", _pickFromGallery),
                    const SizedBox(width: 10),
                    ..._selectedImages.map((file) => Stack(
                      children: [
                        Container(
                          width: 100, height: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                          child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(file, fit: BoxFit.cover)),
                        ),
                        Positioned(
                          right: 5, top: 5,
                          child: GestureDetector(
                            onTap: () => _removeImage(file),
                            child: const CircleAvatar(backgroundColor: Colors.red, radius: 10, child: Icon(Icons.close, size: 12, color: Colors.white)),
                          ),
                        )
                      ],
                    )).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else 
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [Icon(Icons.info, color: Colors.blue), SizedBox(width: 10), Expanded(child: Text("La modification des photos n'est pas encore disponible."))]),
              ),
            
            // --- BOUTON GPS ---
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _locationFound ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _locationFound ? Colors.green : Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(_locationFound ? Icons.check_circle : Icons.location_on, color: _locationFound ? Colors.green : Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _locationFound ? "Position GPS validée" : "Localisation par défaut (Casa)",
                      style: TextStyle(color: _locationFound ? Colors.green[800] : Colors.orange[900], fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (!_locationFound)
                    ElevatedButton(
                      onPressed: _isLocating ? null : _getCurrentLocation,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      child: _isLocating 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : const Text("Localiser"),
                    )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CATEGORIES
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'AUTOMOBILE', label: Text('Auto'), icon: Icon(Icons.directions_car)),
                ButtonSegment(value: 'IMMOBILIER', label: Text('Immo'), icon: Icon(Icons.home)),
                ButtonSegment(value: 'HOTELLERIE', label: Text('Hôtel'), icon: Icon(Icons.hotel)),
              ],
              selected: {_category},
              onSelectionChanged: (Set<String> newSelection) => setState(() => _category = newSelection.first),
            ),
            const SizedBox(height: 20),

            _buildTextField(_titleCtrl, "Titre de l'annonce", icon: Icons.title),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTextField(_priceCtrl, "Prix (MAD)", icon: Icons.attach_money, isNumber: true)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(_phoneCtrl, "Téléphone", icon: Icons.phone, isNumber: true)),
              ],
            ),
            
            // --- 2. COLLER ICI (Juste après le prix) ---
            const SizedBox(height: 15),

            if (_category == 'IMMOBILIER') ...[
              const Text("Type de location", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'jour', child: Text("Location courte (Prix par Jour)")),
                      DropdownMenuItem(value: 'mois', child: Text("Location longue (Prix par Mois)")),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedPeriod = val!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // CHOIX : VENTE ou LOCATION ? 🏠💰
            if (_category != 'HOTELLERIE') ...[ // (Les hôtels sont toujours en location)
               Container(
                 decoration: BoxDecoration(
                   color: Colors.white, 
                   borderRadius: BorderRadius.circular(10),
                   border: Border.all(color: Colors.grey.shade300)
                 ),
                 child: Row(
                   children: [
                     Expanded(
                       child: RadioListTile<String>(
                         title: const Text("Location"),
                         value: 'LOCATION',
                         groupValue: _transactionType,
                         activeColor: const Color(0xFF003580),
                         onChanged: (val) => setState(() => _transactionType = val!),
                       ),
                     ),
                     Expanded(
                       child: RadioListTile<String>(
                         title: const Text("Vente"),
                         value: 'VENTE',
                         groupValue: _transactionType,
                         activeColor: Colors.red,
                         onChanged: (val) => setState(() => _transactionType = val!),
                       ),
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 20),
            ],
            // -------------------------------------------
            _buildTextField(_descCtrl, "Description", icon: Icons.description, maxLines: 3),
            
            const Divider(height: 40, thickness: 2),
            Text("Détails ${_category.toLowerCase()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            if (_category == 'AUTOMOBILE') ...[
              Row(
                children: [
                  Expanded(child: _buildTextField(_brandCtrl, "Marque", icon: Icons.branding_watermark)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_modelCtrl, "Modèle", icon: Icons.car_repair)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildTextField(_yearCtrl, "Année", icon: Icons.calendar_today, isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_kmCtrl, "Kilométrage", icon: Icons.speed, isNumber: true)),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _fuelType,
                decoration: const InputDecoration(labelText: "Carburant", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'DIESEL', child: Text('Diesel')),
                  DropdownMenuItem(value: 'ESSENCE', child: Text('Essence')),
                  DropdownMenuItem(value: 'HYBRIDE', child: Text('Hybride')),
                  DropdownMenuItem(value: 'ELECTRIQUE', child: Text('Électrique')),
                ],
                onChanged: (v) => setState(() => _fuelType = v!),
              ),
            ] else if (_category == 'IMMOBILIER') ...[
              DropdownButtonFormField<String>(
                value: _immoType,
                decoration: const InputDecoration(labelText: "Type de bien", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'APPARTEMENT', child: Text('Appartement')),
                  DropdownMenuItem(value: 'MAISON', child: Text('Maison')),
                  DropdownMenuItem(value: 'TERRAIN', child: Text('Terrain')),
                ],
                onChanged: (v) => setState(() => _immoType = v!),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildTextField(_surfaceCtrl, "Surface (m²)", icon: Icons.square_foot, isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_roomsCtrl, "Pièces", icon: Icons.meeting_room, isNumber: true)),
                ],
              ),
              CheckboxListTile(
                title: const Text("Piscine ?"),
                value: _hasPool,
                onChanged: (v) => setState(() => _hasPool = v!),
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003580), foregroundColor: Colors.white),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(
                      isEditMode ? "ENREGISTRER LES MODIFICATIONS" : "PUBLIER L'ANNONCE", 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, height: 100,
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[400]!)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.grey[700], size: 30), const SizedBox(height: 5), Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 12))]),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {IconData? icon, bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: icon != null ? Icon(icon) : null, border: const OutlineInputBorder()),
      validator: (value) => value == null || value.isEmpty ? 'Requis' : null,
    );
  }

 void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Vérification photo (sauf en edit)
    if (!isEditMode && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ajoutez au moins une photo !")));
      return;
    }

    setState(() => _isLoading = true);

    // ====================================================
    // 🔴 C'EST ICI LA CORRECTION POUR VENTE vs LOCATION
    // ====================================================
    String finalPeriod;

    // 1. Si c'est un HÔTEL -> Toujours "nuit"
    if (_category == 'HOTELLERIE') {
      finalPeriod = 'nuit';
    } 
    // 2. Si l'utilisateur a coché VENTE -> "vente"
    else if (_transactionType == 'VENTE') {
      finalPeriod = 'vente';
    } 
    // 3. Sinon (Location Auto ou Immo)
    else {
      // Si Immo, on regarde si c'est jour ou mois
      if (_category == 'IMMOBILIER') {
        finalPeriod = _selectedPeriod;
      } else {
        // Si Auto, c'est jour par défaut
        finalPeriod = 'jour';
      }
    }
    // ====================================================

    final Map<String, dynamic> data = {
      "title": _titleCtrl.text,
      "description": _descCtrl.text,
      "price": double.tryParse(_priceCtrl.text) ?? 0,
      "category": _category,
      "pricePeriod": finalPeriod, // <--- On envoie la bonne info ici !
      "phone_number": _phoneCtrl.text,
      "latitude": _latitude, 
      "longitude": _longitude,
    };
    
    if (_category == 'AUTOMOBILE') {
      data['detailsAuto'] = {
        "brand": _brandCtrl.text, "model": _modelCtrl.text, "year": int.tryParse(_yearCtrl.text) ?? 2024, "mileage_km": int.tryParse(_kmCtrl.text) ?? 0, "fuel_type": _fuelType,
      };
    } else if (_category == 'IMMOBILIER') {
      data['detailsImmo'] = {
        "type_bien": _immoType, "surface_m2": int.tryParse(_surfaceCtrl.text) ?? 0, "rooms_count": int.tryParse(_roomsCtrl.text) ?? 1, "has_pool": _hasPool, "is_rental": false, 
      };
    }

    bool success;

    if (isEditMode) {
      // --- MODE MODIFICATION ---
      success = await _api.updateAnnonce(widget.annonceAModifier!.id, data);
    } else {
      // --- MODE CREATION ---
      success = await _api.createAnnonce(data, _selectedImages.map((e) => e.path).toList());
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditMode ? "Annonce mise à jour !" : "Annonce publiée !"), backgroundColor: Colors.green)
      );
      context.pop(); 
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur serveur"), backgroundColor: Colors.red));
    }
  }
}