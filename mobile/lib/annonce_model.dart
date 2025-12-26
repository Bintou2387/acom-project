class Annonce {
  final int id;
  final String title;
  final String description;
  final double price;
  final String category;
  final List<String> images;
  final String? coverImage;
  final String? phoneNumber;
  final double latitude;
  final double longitude;
  final bool isBoosted;
  final int views;
  final String? userAvatar; 
  
  // NOUVEAU : L'ID DU VENDEUR
  final int userId; // <--- AJOUT ICI
  final String pricePeriod; // <--- NOUVEAU CHAMP

  final Map<String, dynamic>? detailsAuto;
  final Map<String, dynamic>? detailsImmo;
  final Map<String, dynamic>? detailsHotel;

  Annonce({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.images,
    this.coverImage,
    this.phoneNumber,
    required this.latitude,
    required this.longitude,
    this.isBoosted = false,
    this.views = 0,
    this.userAvatar,
    required this.userId, // <--- AJOUT ICI
    required this.pricePeriod, // <--- AJOUTER ICI
    this.detailsAuto,
    this.detailsImmo,
    this.detailsHotel,
  });

  factory Annonce.fromJson(Map<String, dynamic> json) {
    var list = json['images'] as List? ?? [];
    List<String> imagesList = list.map((i) => i.toString()).toList();
    String? cover = imagesList.isNotEmpty ? imagesList[0] : null;

    double lat = 0.0;
    double lng = 0.0;
    if (json['latitude'] != null) lat = double.tryParse(json['latitude'].toString()) ?? 0.0;
    if (json['longitude'] != null) lng = double.tryParse(json['longitude'].toString()) ?? 0.0;

    String? avatar;
    int vId = 1; // ID par défaut (Admin) si erreur

    // On récupère les infos du vendeur (user)
    if (json['user'] != null) {
      if (json['user']['profilePicture'] != null) avatar = json['user']['profilePicture'];
      if (json['user']['id'] != null) vId = json['user']['id']; // <--- ON RECUPERE L'ID REEL
    }

    return Annonce(
      id: json['id'],
      title: json['title'] ?? "",
      description: json['description'] ?? "",
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      category: json['category'] ?? "AUTRE",
      images: imagesList,
      coverImage: cover,
      phoneNumber: json['phone_number'],
      latitude: lat,
      longitude: lng,
      isBoosted: json['isPromoted'] ?? false,
      views: json['views'] != null ? int.parse(json['views'].toString()) : 0,
      userAvatar: avatar,
      
      userId: vId, // <--- ON STOCKE L'ID
      pricePeriod: json['pricePeriod'] ?? 'jour',

      detailsAuto: json['detailsAuto'],
      detailsImmo: json['detailsImmo'],
      detailsHotel: json['detailsHotel'],
    );
  }
  // PETITE FONCTION UTILITAIRE POUR L'AFFICHAGE
 String get formattedPrice {
    // SI C'EST UNE VENTE : On affiche juste le prix (sans /jour)
    if (pricePeriod == 'vente') {
       // On enlève le .0 si c'est un entier (ex: 150000.0 -> 150000)
       String cleanPrice = price == price.roundToDouble() ? price.toInt().toString() : price.toString();
       return "$cleanPrice MAD"; 
    }

    // SINON C'EST UNE LOCATION
    String suffix = '/jour'; 
    if (pricePeriod == 'mois') suffix = '/mois';
    if (pricePeriod == 'nuit') suffix = '/nuit';
    
    String cleanPrice = price == price.roundToDouble() ? price.toInt().toString() : price.toString();
    
    return "$cleanPrice MAD $suffix";
  }
}
