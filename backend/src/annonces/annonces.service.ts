import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Annonce } from './entities/annonce.entity';
import { User } from '../users/entities/user.entity'; // <--- IMPORT USER
// import { CreateAnnonceDto } from './dto/create-annonce.dto'; // Pas strictement nécessaire si on utilise 'any'

@Injectable()
export class AnnoncesService {
  constructor(
    @InjectRepository(Annonce)
    private readonly annoncesRepository: Repository<Annonce>,
    // AJOUTEZ CECI POUR ACCÉDER AUX UTILISATEURS
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  // CRÉATION SÉCURISÉE
  create(createAnnonceDto: any, user: any) {
    // 1. On prépare la référence utilisateur
    const userRef = { id: user.userId }; 

    // 2. Sécurité : On s'assure que le DTO n'a pas d'ID
    delete createAnnonceDto.id;

    const annonce = this.annoncesRepository.create({
      ...createAnnonceDto,
      user: userRef,
    });

    return this.annoncesRepository.save(annonce);
  }

  // --- NOUVEAU : GESTION DES FAVORIS ---

  // 1. Ajouter ou Retirer des favoris
  async toggleFavorite(userId: number, annonceId: number) {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
      relations: ['favorites'], // On charge la liste actuelle des favoris
    });

    const annonce = await this.annoncesRepository.findOne({ where: { id: annonceId } });

    if (!user || !annonce) {
      throw new NotFoundException('Utilisateur ou Annonce introuvable');
    }

    // Est-ce que l'annonce est déjà dans les favoris ?
    const index = user.favorites.findIndex((fav) => fav.id === annonce.id);

    if (index > -1) {
      // OUI : On la retire (Désolé, je ne t'aime plus)
      user.favorites.splice(index, 1);
    } else {
      // NON : On l'ajoute (Coup de foudre !)
      user.favorites.push(annonce);
    }

    return this.usersRepository.save(user); // On sauvegarde la nouvelle liste
  }

  // 2. Récupérer MA liste de favoris
  async getMyFavorites(userId: number) {
    const user = await this.usersRepository.findOne({
      where: { id: userId },
      relations: ['favorites'],
    });
    return user ? user.favorites : [];
  }

  // RECHERCHE AVANCÉE (Titre + Catégorie + Prix)
  async findAll(title?: string, category?: string, minPrice?: number, maxPrice?: number) {
    const query = this.annoncesRepository.createQueryBuilder('annonce');

    // Filtre par mot-clé
    if (title) {
      query.andWhere('annonce.title ILIKE :title', { title: `%${title}%` });
    }

    // Filtre par catégorie
    if (category) {
      query.andWhere('annonce.category = :category', { category });
    }

    // Filtre Prix Minimum
    if (minPrice) {
      query.andWhere('annonce.price >= :minPrice', { minPrice });
    }

    // Filtre Prix Maximum
    if (maxPrice) {
      query.andWhere('annonce.price <= :maxPrice', { maxPrice });
    }

    // Tri et relations
    return await query
      .leftJoinAndSelect('annonce.user', 'user')
      // RÈGLE D'OR DU BUSINESS : Les payants d'abord !
      .addOrderBy('annonce.isPromoted', 'DESC') // DESC met les TRUE (payants) avant les FALSE
      .addOrderBy('annonce.id', 'DESC') // Ensuite, les plus récents
      .getMany();
  }

  // MES ANNONCES (PROFIL)
  async findMine(userId: number) {
    return this.annoncesRepository.find({
      where: { user: { id: userId } },
      order: { id: 'DESC' }
    });
  }

  // DÉTAIL D'UNE ANNONCE
  async findOne(id: number) {
    const annonce = await this.annoncesRepository.findOne({ 
      where: { id },
      relations: ['user'] 
    });
    
    if (!annonce) {
      throw new NotFoundException(`Annonce #${id} non trouvée`);
    }

    // AJOUTER +1 VUE 👁️
    // On ne veut pas attendre la sauvegarde pour répondre à l'utilisateur, 
    // donc on lance l'update mais on n'attend pas forcément le résultat (optimisation)
    this.annoncesRepository.increment({ id }, 'views', 1);

    return annonce;
  }

  // SUPPRESSION SÉCURISÉE (Celle qu'on garde !)
  async remove(id: number, userId: number) {
    const annonce = await this.annoncesRepository.findOne({
      where: { id: id, user: { id: userId } } // On vérifie que c'est bien SON annonce
    });

    if (!annonce) {
      throw new NotFoundException("Annonce introuvable ou vous n'êtes pas le propriétaire");
    }

    return this.annoncesRepository.remove(annonce);
  }

// ... code existant ...

  // MISE À JOUR SÉCURISÉE
  async update(id: number, updateAnnonceDto: any, userId: number) {
    // 1. On vérifie que l'annonce appartient bien à l'utilisateur
    const annonce = await this.annoncesRepository.findOne({
      where: { id: id, user: { id: userId } }
    });

    if (!annonce) {
      throw new NotFoundException("Annonce introuvable ou vous n'êtes pas le propriétaire");
    }

    // 2. On met à jour (sans toucher à l'ID ni à l'User)
    delete updateAnnonceDto.id;
    delete updateAnnonceDto.userId;

    // On applique les modifications
    await this.annoncesRepository.update(id, updateAnnonceDto);

    // 3. On retourne l'annonce mise à jour
    return this.findOne(id);
  }
  // CHEAT CODE : Pour booster une annonce manuellement
  async boostAnnonce(id: number) {
    await this.annoncesRepository.update(id, { isPromoted: true });
    return { message: `L'annonce ${id} est maintenant SPONSORISÉE ! 🚀` };
  }

  // RETIRER LE BOOST
  async unboostAnnonce(id: number) {
    await this.annoncesRepository.update(id, { isPromoted: false });
    return { message: "Boost retiré." };
  }
}