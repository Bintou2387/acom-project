import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // <--- IMPORT
import 'dart:io'; // <--- IMPORT
import 'api_service.dart';
import 'annonce_model.dart';
import 'auth_page.dart';
import 'add_annonce_page.dart';
import 'admin_dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _api = ApiService();
  late Future<List<Annonce>> _myAnnonces;
  String _userName = "Utilisateur";
  String _userRole = "user";
  String? _avatarFile; // Nom du fichier sur le serveur

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _refreshAnnonces();
  }

  void _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? "Utilisateur";
      _userRole = prefs.getString('user_role') ?? "user";
      // On récupère l'avatar sauvegardé localement
      _avatarFile = prefs.getString('user_avatar'); 
    });
  }

  void _refreshAnnonces() {
    setState(() {
      _myAnnonces = _api.getMyAnnonces();
    });
  }

  // --- NOUVEAU : CHOISIR ET UPLOADER L'IMAGE ---
  void _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // 1. On montre un chargement (optionnel, mais mieux)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Envoi de la photo...")));

      // 2. On envoie au serveur
      String? filename = await _api.uploadProfilePicture(File(pickedFile.path));

      if (filename != null) {
        // 3. On sauvegarde le résultat
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_avatar', filename);

        setState(() {
          _avatarFile = filename;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Photo de profil mise à jour ! ✨"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erreur lors de l'envoi"), backgroundColor: Colors.red));
      }
    }
  }

  void _logout() async {
    await _api.logout();
    if (mounted) context.go('/');
  }

  void _delete(int id) async {
    // ... (Code existant de suppression) ...
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await _api.deleteAnnonce(id);
      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Annonce supprimée"), backgroundColor: Colors.green));
        _refreshAnnonces();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Profil"),
        backgroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: _logout)
        ],
      ),
      body: Column(
        children: [
          // EN-TÊTE PROFIL (MODIFIÉ)
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                // --- AVATAR CLIQUABLE ---
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: const Color(0xFF003580),
                        backgroundImage: _avatarFile != null 
                          ?NetworkImage("${ApiService.baseUrl}/$_avatarFile") // Image du serveur (Notez le /uploads/ que j'ajoute ici car le backend sert les fichiers statiques à la racine ou via un préfixe, on va vérifier ça)
                          : null,
                        child: _avatarFile == null 
                          ? Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : "U", style: const TextStyle(color: Colors.white, fontSize: 28))
                          : null,
                      ),
                      // Petite icône appareil photo
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.black),
                        ),
                      )
                    ],
                  ),
                ),
                
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(_userRole == 'admin' ? "Administrateur 👮‍♂️" : "Membre Acom", style: TextStyle(color: _userRole == 'admin' ? Colors.red : Colors.grey, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1),

          const SizedBox(height: 20),
          
          if (_userRole == 'admin') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AdminDashboardPage()));
                },
                icon: const Icon(Icons.security, color: Colors.white),
                label: const Text("PANNEAU ADMIN"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
              ),
            ),
            const Divider(height: 40),
          ],
          
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Align(alignment: Alignment.centerLeft, child: Text("Mes Annonces", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ),

          Expanded(
            child: FutureBuilder<List<Annonce>>(
              future: _myAnnonces,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Vous n'avez aucune annonce."));

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final annonce = snapshot.data![index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      elevation: 2,
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: SizedBox(
                            width: 60, height: 60,
                            child: annonce.coverImage != null 
                              ? Image.network("${ApiService.baseUrl}/${annonce.coverImage}", fit: BoxFit.cover)
                              : const Icon(Icons.image),
                          ),
                        ),
                        title: Text(annonce.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text("${annonce.price} MAD", style: const TextStyle(color: Color(0xFF003580), fontWeight: FontWeight.bold)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (context) => AddAnnoncePage(annonceAModifier: annonce))); _refreshAnnonces(); }),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(annonce.id)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}