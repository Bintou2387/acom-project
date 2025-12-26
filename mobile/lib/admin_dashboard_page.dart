import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';
import 'annonce_model.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final ApiService _api = ApiService();
  List<Annonce> _annonces = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAllAnnonces();
  }

  // Récupérer TOUTES les annonces (sans filtre)
  void _fetchAllAnnonces() async {
    final list = await _api.getAnnonces(); // Récupère tout
    setState(() {
      _annonces = list;
      _isLoading = false;
    });
  }

  // FONCTION CLÉ : Activer/Désactiver le Boost
  void _toggleBoost(Annonce annonce) async {
    final String action = annonce.isBoosted ? "unboost" : "boost";
    
    // Appel direct aux routes qu'on a créées (optimiste update)
    final url = Uri.parse('${ApiService.baseUrl}/annonces/${annonce.id}/$action');
    
    try {
      final response = await http.get(url); // On appelle la route GET simple
      if (response.statusCode == 200 || response.statusCode == 201) {
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(annonce.isBoosted ? "Boost retiré 📉" : "Annonce BOOSTÉE ! 🚀"),
            backgroundColor: annonce.isBoosted ? Colors.grey : Colors.amber,
          )
        );
        _fetchAllAnnonces(); // Rafraîchir la liste
      }
    } catch (e) {
      print("Erreur boost: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panneau Administrateur", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87, // Look "Sérieux" pour l'admin
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.separated(
            itemCount: _annonces.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (ctx, index) {
              final annonce = _annonces[index];
              return ListTile(
                leading: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    border: annonce.isBoosted ? Border.all(color: Colors.amber, width: 2) : null,
                    borderRadius: BorderRadius.circular(5)
                  ),
                  child: annonce.coverImage != null 
                    ? Image.network("${ApiService.baseUrl}/${annonce.coverImage}", fit: BoxFit.cover)
                    : const Icon(Icons.image),
                ),
                title: Text(annonce.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text("${annonce.price} MAD - ${annonce.category}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicateur visuel
                    if (annonce.isBoosted) const Icon(Icons.star, color: Colors.amber),
                    const SizedBox(width: 10),
                    // L'INTERRUPTEUR DE POUVOIR ⚡
                    Switch(
                      value: annonce.isBoosted,
                      activeColor: Colors.amber,
                      onChanged: (val) => _toggleBoost(annonce),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}