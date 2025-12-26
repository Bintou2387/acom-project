import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'annonce_model.dart';
import 'main.dart'; // Pour accéder à AnnonceDetailSheet

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final ApiService _api = ApiService();
  late Future<List<Annonce>> _favorites;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _favorites = _api.getMyFavorites();
    });
  }

  // Fonction pour retirer des favoris directement depuis cette liste
  void _removeFavorite(int id) async {
    await _api.toggleFavorite(id); // Ça agit comme un interrupteur (On -> Off)
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Retiré des favoris 💔")));
    _refresh(); // On recharge la liste pour faire disparaître l'élément
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Coups de ❤️"),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false, // Pas de flèche retour car c'est un onglet principal
      ),
      body: FutureBuilder<List<Annonce>>(
        future: _favorites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("Aucun favori pour l'instant", style: TextStyle(color: Colors.grey, fontSize: 18)),
                ],
              ),
            );
          }

          final favs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: favs.length,
            itemBuilder: (context, index) {
              final annonce = favs[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 70, height: 70,
                      child: annonce.coverImage != null 
                        ? Image.network("${ApiService.baseUrl}/${annonce.coverImage}", fit: BoxFit.cover)
                        : const Icon(Icons.image),
                    ),
                  ),
                  title: Text(annonce.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${annonce.price} MAD", style: const TextStyle(color: Color(0xFF003580), fontWeight: FontWeight.w900)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          Text("Casablanca", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      )
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.highlight_remove, color: Colors.red),
                    onPressed: () => _removeFavorite(annonce.id),
                  ),
                  onTap: () {
                    // Ouvre la fiche détail quand on clique sur l'élément
                    showModalBottomSheet(
                      context: context, 
                      isScrollControlled: true, 
                      builder: (ctx) => AnnonceDetailSheet(annonce: annonce)
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}