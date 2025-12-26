import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // <--- IMPORT 1

// Mes imports
import 'api_service.dart';
import 'annonce_model.dart';
import 'auth_page.dart';
import 'add_annonce_page.dart';
import 'profile_page.dart';
import 'favorites_page.dart';
import 'ad_banner.dart'; // <--- IMPORT 2 (Notre fichier créé)
import 'chat_page.dart';


void main() async { // <--- Ajouter async
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize(); // <--- INITIALISER ADMOB
  runApp(const MyApp());
}

// CONFIGURATION DU ROUTER
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainScreen()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
    GoRoute(path: '/add', builder: (context, state) => const AddAnnoncePage()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'Acom',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF003580)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5), // Fond gris clair moderne
      ),
    );
  }
}

// ==========================================
// ECRAN PRINCIPAL (ACCUEIL)
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final ApiService api = ApiService();
  late Future<List<Annonce>> futureAnnonces;
  
  // Variables de recherche...
  String _searchKeyword = "";
  String? _selectedCategory;
  double? _minPrice;
  double? _maxPrice;
  final TextEditingController _searchCtrl = TextEditingController();

  // --- 1. COLLER ICI (La variable pour stocker le choix) ---
  bool _sortByCheapest = false;

  // --- NOUVEAU : Variable pour la photo de profil ---
  String? _userAvatar; 

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadAvatar(); // <--- ON LANCE LE CHARGEMENT ICI
  }

  // --- NOUVELLE FONCTION ---
  void _loadAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userAvatar = prefs.getString('user_avatar'); // On récupère le nom du fichier
    });
  }


  // --- 2. REMPLACER TOUTE LA FONCTION _fetchData PAR CELLE-CI ---
  void _fetchData() {
    setState(() {
      futureAnnonces = api.getAnnonces(
        keyword: _searchKeyword,
        category: _selectedCategory,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      ).then((list) {
        // C'EST ICI QU'ON TRIE 📉
        if (_sortByCheapest) {
          // On compare le prix A au prix B
          list.sort((a, b) => a.price.compareTo(b.price));
        }
        return list;
      });
    });
  }

  void _onCategorySelect(String? category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null; // Désélectionner
      } else {
        _selectedCategory = category;
      }
    });
    _fetchData();
  }

  // --- FONCTION POUR AFFICHER LE PANNEAU DE FILTRES (COMPLÈTE) ---
  void _showFilterModal() {
    final minCtrl = TextEditingController(text: _minPrice?.toStringAsFixed(0) ?? "");
    final maxCtrl = TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, 
          left: 20, right: 20, top: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Filtrer par budget", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            
            const SizedBox(height: 20),
            
            // 1. CHAMPS MIN / MAX
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Min (MAD)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.money_off)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Max (MAD)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // ===============================================
            // 2. NOUVEAU BLOC : ORDRE D'AFFICHAGE (TRI) 📉
            // ===============================================
            const Text("Ordre d'affichage", style: TextStyle(fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: const Text("Prix le plus bas en premier 📉"),
              value: _sortByCheapest,
              activeColor: const Color(0xFF003580),
              onChanged: (val) {
                // Note : Dans un Modal simple, le switch ne bougera peut-être pas visuellement 
                // instantanément sans un StatefulBuilder, mais la valeur sera bien enregistrée.
                setState(() {
                  _sortByCheapest = val;
                });
                // Astuce : On force la fermeture/réouverture pour voir l'effet visuel ou on laisse tel quel.
                // Pour l'instant, c'est suffisant car on clique sur "Appliquer" juste après.
              },
            ),
            // ===============================================

            const SizedBox(height: 20),

            // 3. BOUTONS D'ACTION (Effacer / Appliquer)
            Row(
              children: [
                TextButton(
                  onPressed: () {
                      setState(() {
                        _minPrice = null;
                        _maxPrice = null;
                        _sortByCheapest = false; // On remet à zéro le tri aussi
                      });
                      _fetchData();
                      Navigator.pop(ctx);
                  }, 
                  child: const Text("Effacer", style: TextStyle(color: Colors.red))
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _minPrice = double.tryParse(minCtrl.text);
                      _maxPrice = double.tryParse(maxCtrl.text);
                    });
                    _fetchData(); // C'est ici que le tri s'applique vraiment
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003580), foregroundColor: Colors.white),
                  child: const Text("Appliquer les filtres"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getBody(), // Appel de la fonction qui gère l'affichage
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min, // Important pour ne pas prendre tout l'écran
        children: [
          // LA BANNIÈRE PUBLICITAIRE 💸
          const AdBanner(),
          
          // LA BARRE DE NAVIGATION CLASSIQUE
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.grid_view), label: 'Liste'),
              NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Carte'),
              NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite, color: Colors.red), label: 'Favoris'),
            ],
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton.extended(
        onPressed: () async {
          bool loggedIn = await api.isLoggedIn();
          if (loggedIn && context.mounted) {
            context.push('/add').then((_) => _fetchData());
          } else if (context.mounted) {
            context.push('/auth');
          }
        },
        label: const Text("Vendre"),
        icon: const Icon(Icons.camera_alt),
        backgroundColor: const Color(0xFF003580),
        foregroundColor: Colors.white,
      ) : null,
    );
  }

  // --- LE CORPS DE LA PAGE (CORRIGÉ) ---
  Widget _getBody() {
    // 1. ONGLET FAVORIS
    if (_selectedIndex == 2) {
      return const FavoritesPage();
    }

    return FutureBuilder<List<Annonce>>(
      future: futureAnnonces,
      builder: (context, snapshot) {
        final annonces = snapshot.data ?? [];
        final bool isLoading = snapshot.connectionState == ConnectionState.waiting;

        // 2. ONGLET CARTE
        if (_selectedIndex == 1) {
          return MapView(annonces: annonces);
        }

        // 3. ONGLET ACCUEIL (SCROLLVIEW)
        return CustomScrollView(
          slivers: [
            // A. BARRE DE RECHERCHE + PROFIL
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: const Color(0xFFF0F2F5),
              surfaceTintColor: Colors.white,
              toolbarHeight: 80,
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
                child: Row(
                  children: [
                    // BARRE DE RECHERCHE
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            hintText: "Que cherchez-vous ?",
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF003580)),
                            suffixIcon: _searchKeyword.isNotEmpty 
                              ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() => _searchKeyword = ""); _fetchData(); }) 
                              : IconButton(icon: Icon(Icons.tune, color: (_minPrice != null || _maxPrice != null) ? const Color(0xFF003580) : Colors.grey), onPressed: _showFilterModal),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                          ),
                          onSubmitted: (value) { setState(() => _searchKeyword = value); _fetchData(); },
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    
                    // BOUTON PROFIL (AVEC PHOTO)
                    GestureDetector(
                      onTap: () async {
                        bool loggedIn = await api.isLoggedIn();
                        if (loggedIn) {
                          context.push('/profile').then((_) => _loadAvatar()); 
                        } else {
                          context.push('/auth');
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)]
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white,
                          backgroundImage: _userAvatar != null 
                            ? NetworkImage("${ApiService.baseUrl}/$_userAvatar") 
                            : null,
                          child: _userAvatar == null 
                            ? const Icon(Icons.person, color: Color(0xFF003580)) 
                            : null,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

            // B. SECTION CATÉGORIES
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Catégories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCategoryItem("Tout", Icons.dashboard, Colors.grey, null),
                        _buildCategoryItem("Auto", Icons.directions_car, Colors.blue, "AUTOMOBILE"),
                        _buildCategoryItem("Immo", Icons.home, Colors.orange, "IMMOBILIER"),
                        _buildCategoryItem("Hôtel", Icons.hotel, Colors.purple, "HOTELLERIE"),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // C. TITRE LISTE
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text("Dernières Annonces", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ),

            // D. GRILLE DES ANNONCES
            if (isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (snapshot.hasError)
               SliverFillRemaining(child: Center(child: Text("Erreur de chargement", style: const TextStyle(color: Colors.red))))
            else if (annonces.isEmpty)
              const SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 60, color: Colors.grey), SizedBox(height: 10), Text("Aucun résultat", style: TextStyle(color: Colors.grey))])))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15),
                  delegate: SliverChildBuilderDelegate((ctx, index) => AnnonceGridCard(annonce: annonces[index]), childCount: annonces.length),
                ),
              ),
            
            // E. ESPACE EN BAS
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        );
      },
    );
  }
  
  // --- NOUVELLE FONCTION POUR DESSINER LES ICÔNES ---
  Widget _buildCategoryItem(String label, IconData icon, Color color, String? code) {
    bool isSelected = _selectedCategory == code;
    return GestureDetector(
      onTap: () => _onCategorySelect(code),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isSelected ? color : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                if (!isSelected) BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
              ],
              border: isSelected ? null : Border.all(color: Colors.grey[200]!)
            ),
            child: Icon(icon, color: isSelected ? Colors.white : color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey[600],
              fontSize: 12
            )
          )
        ],
      ),
    );
  }
} // <--- C'est ICI que ça manquait ! La fin de _MainScreenState

// ==========================================
// WIDGET CARTE (MAP VIEW)
// ==========================================
class MapView extends StatefulWidget {
  final List<Annonce> annonces;
  const MapView({super.key, required this.annonces});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  Annonce? _selectedAnnonce;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(33.5731, -7.5898), // Casablanca
            initialZoom: 12.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.acom.app',
            ),
            MarkerLayer(
              markers: widget.annonces.map((annonce) {
                return Marker(
                  point: LatLng(annonce.latitude, annonce.longitude),
                  width: 80,
                  height: 80,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAnnonce = annonce;
                      });
                      // Ouvrir le détail
                      showModalBottomSheet(
                        context: context, 
                        isScrollControlled: true, 
                        builder: (ctx) => AnnonceDetailSheet(annonce: _selectedAnnonce!)
                      );
                    },
                    child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }
}

// ==========================================
// FICHE DÉTAIL (AVEC CHAT 💬 + FAVORIS ❤️)
// ==========================================
class AnnonceDetailSheet extends StatefulWidget {
  final Annonce annonce;
  const AnnonceDetailSheet({super.key, required this.annonce});

  @override
  State<AnnonceDetailSheet> createState() => _AnnonceDetailSheetState();
}

class _AnnonceDetailSheetState extends State<AnnonceDetailSheet> {
  final ApiService _api = ApiService();
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _api.viewAnnonce(widget.annonce.id); 
  }

  void _launchWhatsApp() async {
    String phone = (widget.annonce.phoneNumber ?? "").replaceAll(RegExp(r'\s+'), '');
    if (phone.isEmpty) return;
    if (phone.startsWith('0')) {
      phone = '212${phone.substring(1)}';
    }
    final Uri url = Uri.parse("https://wa.me/$phone");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print("Impossible d'ouvrir WhatsApp");
    }
  }

  void _launchSMS() async {
    final Uri url = Uri.parse("sms:${widget.annonce.phoneNumber ?? ""}");
    if (!await launchUrl(url)) {
      print("Impossible d'ouvrir les SMS");
    }
  }

  void _toggleHeart() async {
    bool loggedIn = await _api.isLoggedIn();
    if (!loggedIn) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Connectez-vous pour ajouter aux favoris !")));
      return;
    }

    bool success = await _api.toggleFavorite(widget.annonce.id);
    if (success && mounted) {
      setState(() {
        _isLiked = !_isLiked;
      });
      String msg = _isLiked ? "Ajouté aux favoris ❤️" : "Retiré des favoris 💔";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9, 
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: ListView(controller: controller, padding: EdgeInsets.zero, children: [
              // Image
              Stack(
                children: [
                  SizedBox(
                    height: 300, 
                    child: widget.annonce.images.isNotEmpty 
                      ? PageView.builder(itemCount: widget.annonce.images.length, itemBuilder: (ctx, i) => Image.network("${ApiService.baseUrl}/${widget.annonce.images[i]}", fit: BoxFit.cover)) 
                      : Image.asset('assets/car.jpg', fit: BoxFit.cover)
                  ),
                  Positioned(
                    top: 10, right: 10,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border),
                        color: Colors.red,
                        onPressed: _toggleHeart,
                      ),
                    ),
                  )
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.all(20), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(widget.annonce.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    
                    // --- CORRECTION ICI ---
                    // 1. On a ajouté "widget." devant annonce
                    // 2. On a ajouté la virgule "," à la fin de la parenthèse
                    Text(
                      widget.annonce.formattedPrice, 
                      style: const TextStyle(fontSize: 20, color: Color(0xFF003580), fontWeight: FontWeight.bold)
                    ),
                    
                    const SizedBox(height: 20), 
                    // -----------------------

                    const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.annonce.description, style: const TextStyle(color: Colors.grey)),
                    
                    const SizedBox(height: 40),
                    
                    // --- NOUVEAUX BOUTONS ---
                    Row(
                      children: [
                        // BOUTON DISCUTER (Chat Acom)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              bool loggedIn = await _api.isLoggedIn();
                              if (!loggedIn) {
                                 context.push('/auth');
                                 return;
                              }
                              
                              // OUVERTURE DU CHAT (DYNAMIQUE)
                              Navigator.push(context, MaterialPageRoute(builder: (ctx) => ChatPage(
                                contactId: widget.annonce.userId, // <--- C'est le vrai ID maintenant !
                                contactName: "Vendeur", // (Bonus: Vous pourriez aussi passer le nom du vendeur via le modèle)
                              )));
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text("Discuter"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003580),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 10),
                        
                        // BOUTON WHATSAPP (Vert)
                        Container(
                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10)),
                          child: IconButton(
                            icon: const Icon(Icons.call, color: Colors.white),
                            onPressed: _launchWhatsApp,
                            padding: const EdgeInsets.all(12),
                          ),
                        )
                      ],
                    ),
                    
                    // (Optionnel) Un petit lien pour SMS/Appel classique en dessous si besoin
                    const SizedBox(height: 15),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => launchUrl(Uri.parse("tel:${widget.annonce.phoneNumber ?? ""}")),
                        icon: const Icon(Icons.phone, size: 16, color: Colors.grey),
                        label: const Text("Appel téléphonique classique", style: TextStyle(color: Colors.grey)),
                      ),
                    )
              ])),
          ]),
        ),
      );
  }
}
// ==========================================
// CARTE GRILLE (DESIGN FINAL : PREMIUM + VUES + AVATAR 📸)
// ==========================================
class AnnonceGridCard extends StatelessWidget {
  final Annonce annonce;
  const AnnonceGridCard({super.key, required this.annonce});

  String _getPlaceholderImage() {
    if (annonce.category == 'AUTOMOBILE') return 'assets/car.jpg';
    if (annonce.category == 'IMMOBILIER') return 'assets/house.jpg';
    return 'assets/car.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => AnnonceDetailSheet(annonce: annonce)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: annonce.isBoosted ? Border.all(color: Colors.amber, width: 2) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- IMAGE ---
            Expanded(
              child: Stack( 
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)), 
                    child: annonce.coverImage != null 
                      ? Image.network("${ApiService.baseUrl}/${annonce.coverImage}", fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                      : Image.asset(_getPlaceholderImage(), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  ),
                  if (annonce.isBoosted)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))]),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.star, size: 10, color: Colors.black), SizedBox(width: 4), Text("SPONSORISÉ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black))]),
                      ),
                    )
                ],
              ),
            ),
            
            // --- INFOS AVEC AVATAR ---
            Padding(
              padding: const EdgeInsets.all(8), // Un peu moins de padding
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. L'AVATAR DU VENDEUR (Rond)
                  CircleAvatar(
                    radius: 12, // Tout petit
                    backgroundColor: Colors.grey[200],
                    backgroundImage: annonce.userAvatar != null 
                        ? NetworkImage("${ApiService.baseUrl}/${annonce.userAvatar}")
                        : null,
                    child: annonce.userAvatar == null 
                        ? const Icon(Icons.person, size: 14, color: Colors.grey) 
                        : null,
                  ),
                  const SizedBox(width: 8),

                  // 2. LES TEXTES
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Catégorie + Vues
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(annonce.category, style: TextStyle(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                            if (annonce.isBoosted) 
                              const Icon(Icons.bolt, size: 14, color: Colors.amber)
                            else 
                              Row(children: [Icon(Icons.remove_red_eye, size: 10, color: Colors.grey[400]), const SizedBox(width: 2), Text("${annonce.views}", style: TextStyle(fontSize: 9, color: Colors.grey[600]))]),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(annonce.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(annonce.formattedPrice, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF003580)))
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}