import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'annonce_model.dart';
import 'dart:io';
import 'message_model.dart';

class ApiService {
  // ⚠️ Vérifiez toujours votre IP (ex: 192.168.1.12 ou 10.0.2.2 pour émulateur)
  static const String baseUrl = "http://192.168.137.1:3000"; 

  // --- AUTHENTIFICATION ---

  // Inscription
  Future<bool> signup(String email, String password, String fullName, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
          "fullName": fullName,
          "phone": phone
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Erreur signup: $e");
      return false;
    }
  }

  // Connexion
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_id', data['user_id'].toString());
        await prefs.setString('user_name', data['name']);
        
        // --- SAUVEGARDE DU RÔLE ---
        // Si le serveur ne renvoie rien (ancien compte), on met 'user' par défaut
        await prefs.setString('user_role', data['role'] ?? 'user'); 
        
        return true;
      }
      return false;
    } catch (e) {
      print("Erreur login: $e");
      return false;
    }
  }

  // Vérifier si connecté
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }

  // Déconnexion
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // --- ANNONCES (LECTURE PUBLIQUE) ---
  
  Future<List<Annonce>> getAnnonces({String? keyword, String? category, double? minPrice, double? maxPrice}) async {
    try {
      // Construction intelligente de l'URL
      List<String> params = [];
      if (keyword != null && keyword.isNotEmpty) params.add("title=$keyword");
      if (category != null && category.isNotEmpty) params.add("category=$category");
      
      // AJOUT DES PRIX
      if (minPrice != null) params.add("minPrice=$minPrice");
      if (maxPrice != null) params.add("maxPrice=$maxPrice");

      String queryParams = params.isNotEmpty ? "?${params.join('&')}" : "";

      final response = await http.get(Uri.parse('$baseUrl/annonces$queryParams'));
      
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Annonce.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Erreur getAnnonces: $e");
      return [];
    }
  }

  // --- ANNONCES (GESTION UTILISATEUR / PROFIL) ---

  // 1. Récupérer MES annonces (Nouveau)
  Future<List<Annonce>> getMyAnnonces() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/annonces/mine'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Annonce.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Erreur getMyAnnonces: $e");
      return [];
    }
  }

  // 2. Supprimer une annonce (Nouveau)
  Future<bool> deleteAnnonce(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/annonces/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Erreur deleteAnnonce: $e");
      return false;
    }
  }
    // --- CRÉATION ANNONCE ---

  Future<bool> createAnnonce(Map<String, dynamic> data, List<String> imagePaths) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/annonces'));
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    data.forEach((key, value) {
      if (value is Map) {
         request.fields[key] = jsonEncode(value);
      } else {
         request.fields[key] = value.toString();
      }
    });

    for (String path in imagePaths) {
      request.files.add(await http.MultipartFile.fromPath('images', path));
    }

    try {
      var response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
   // ... code existant ...

  // Mettre à jour une annonce
  Future<bool> updateAnnonce(int id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    try {
      final response = await http.patch( // Attention: c'est PATCH, pas POST
        Uri.parse('$baseUrl/annonces/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Erreur update: $e");
      return false;
    }
  }

  // --- FAVORIS (Wishlist) ---

  // 1. Ajouter ou Retirer des favoris (Toggle)
  Future<bool> toggleFavorite(int annonceId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/annonces/$annonceId/favorite'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 201; // 201 Created = Succès
    } catch (e) {
      print("Erreur favoris: $e");
      return false;
    }
  }

  // 2. Récupérer MES favoris
  Future<List<Annonce>> getMyFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/annonces/favorites/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Annonce.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("Erreur getMyFavorites: $e");
      return [];
    }
  }
// ... autres méthodes ...

  // SIGNALER QU'ON REGARDE UNE ANNONCE (Pour incrémenter les vues)
  Future<void> viewAnnonce(int id) async {
    try {
      // On appelle simplement l'endpoint GET /annonces/:id
      // Le Backend va automatiquement faire +1 vue grâce à votre modification précédente
      await http.get(Uri.parse('$baseUrl/annonces/$id'));
    } catch (e) {
      print("Erreur lors de la vue: $e");
    }
  }

  // ... autres méthodes ...

  // UPLOAD PHOTO PROFIL
  Future<String?> uploadProfilePicture(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/upload'));
      request.headers['Authorization'] = 'Bearer $token';
      
      // Ajout du fichier
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['filename']; // Le serveur renvoie le nom du fichier
      }
      return null;
    } catch (e) {
      print("Erreur upload avatar: $e");
      return null;
    }
  }

  // Récupérer les infos complètes de l'utilisateur (pour avoir la photo à jour)
  // On crée une petite méthode pour ça, car login ne suffit plus
  Future<Map<String, dynamic>?> getMyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('user_id');
    if (token == null || userId == null) return null;

    // On triche un peu : comme on n'a pas fait de route "GET /users/me", 
    // on va supposer qu'on peut récupérer l'info via les annonces ou autre,
    // MAIS le plus simple pour l'instant est de stocker l'URL locale après l'upload.
    // Pour bien faire, il faudrait une route "GET /users/profile" au backend.
    // On va faire simple : On stocke la photo dans le téléphone après l'upload.
    return null;
  }
  // --- GESTION MESSAGERIE ---

  // 1. Lire la discussion avec une personne (contactId)
  Future<List<Message>> getConversation(int contactId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/messages/conversation/$contactId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Message.fromJson(item)).toList();
    } else {
      return [];
    }
  }

  // 2. Envoyer un message
  Future<bool> sendMessage(int receiverId, String content) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        "receiverId": receiverId,
        "content": content,
      }),
    );

    return response.statusCode == 201;
  }
} // Fin de la classe
