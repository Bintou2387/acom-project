import { Controller, Get, Post, Body, Param, UseInterceptors, UploadedFiles, Query, UseGuards, Request , Delete , Patch } from '@nestjs/common';
import { AnnoncesService } from './annonces.service';
import { FilesInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // <--- IMPORTER LE GARDIEN (Vérifiez le chemin)

@Controller('annonces')
export class AnnoncesController {
  constructor(private readonly annoncesService: AnnoncesService) {}

  @Post()
  @UseGuards(JwtAuthGuard) // <--- 🔒 SEULS LES CONNECTÉS PEUVENT POSTER
  @UseInterceptors(FilesInterceptor('images', 10, {
    storage: diskStorage({
      destination: './uploads',
      filename: (req, file, callback) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        const ext = extname(file.originalname);
        callback(null, `${file.fieldname}-${uniqueSuffix}${ext}`);
      },
    }),
  }))
  create(@Body() createAnnonceDto: any, @UploadedFiles() files: Array<any>, @Request() req: any) { // <--- ON RÉCUPÈRE LA REQUÊTE (req)
    
    // 1. Gestion des Images
    createAnnonceDto.images = [];
    if (files && files.length > 0) {
      files.forEach(file => {
        createAnnonceDto.images.push(`uploads/${file.filename}`);
      });
    }

    // 2. Conversions (String -> Number/JSON)
    if (typeof createAnnonceDto.price === 'string') createAnnonceDto.price = parseFloat(createAnnonceDto.price);
    if (typeof createAnnonceDto.latitude === 'string') createAnnonceDto.latitude = parseFloat(createAnnonceDto.latitude);
    if (typeof createAnnonceDto.longitude === 'string') createAnnonceDto.longitude = parseFloat(createAnnonceDto.longitude);

    if (createAnnonceDto.detailsAuto && typeof createAnnonceDto.detailsAuto === 'string') {
        try { createAnnonceDto.detailsAuto = JSON.parse(createAnnonceDto.detailsAuto); } catch(e) {}
    }
    if (createAnnonceDto.detailsImmo && typeof createAnnonceDto.detailsImmo === 'string') {
        try { createAnnonceDto.detailsImmo = JSON.parse(createAnnonceDto.detailsImmo); } catch(e) {}
    }

    // 3. ON ATTACHE L'UTILISATEUR (qui est dans req.user grâce au Token)
    const user = req.user; 
    
    // On passe tout au service
    return this.annoncesService.create(createAnnonceDto, user);
  }

  
  
  // AJOUTEZ CECI AVANT @Get(':id')
  @Get('mine')
  @UseGuards(JwtAuthGuard) // Sécurité activée
  findMine(@Request() req: any) {
    return this.annoncesService.findMine(req.user.userId);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard) // Sécurité activée
  remove(@Param('id') id: string, @Request() req: any) {
    return this.annoncesService.remove(+id, req.user.userId);
  }

  // ... le reste du code (@Get(':id') etc.) ...

  // ... (Le reste des méthodes findAll, findOne ne change pas pour l'instant)
  @Get()
  findAll(
    @Query('title') title: string,
    @Query('category') category: string,
    @Query('minPrice') minPrice: string, // On reçoit une string
    @Query('maxPrice') maxPrice: string, // On reçoit une string
  ) {
    // Le '+' devant convertit la string en nombre (ex: "100" -> 100)
    // Si la string est vide, le '+' donnera 0 ou NaN, donc on gère ça :
    const min = minPrice ? +minPrice : undefined;
    const max = maxPrice ? +maxPrice : undefined;

    return this.annoncesService.findAll(title, category, min, max);
  }

  // Route pour tester le boost : http://localhost:3000/annonces/1/boost
  @Get(':id/boost')
  boost(@Param('id') id: string) {
    return this.annoncesService.boostAnnonce(+id);
  }

  // Route pour ENLEVER le boost
  @Get(':id/unboost')
  unboost(@Param('id') id: string) {
    return this.annoncesService.unboostAnnonce(+id);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.annoncesService.findOne(+id);
  }
// ... code existant ...

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  update(@Param('id') id: string, @Body() body: any, @Request() req: any) {
    // Pour l'instant, on gère la mise à jour texte/prix
    // (Les images demanderaient une logique plus complexe qu'on verra plus tard)
    return this.annoncesService.update(+id, body, req.user.userId);
  }
  // ... imports ...

  // 1. VOIR MES FAVORIS (A mettre AVANT @Get(':id'))
  @Get('favorites/me')
  @UseGuards(JwtAuthGuard)
  getMyFavorites(@Request() req: any) {
    return this.annoncesService.getMyFavorites(req.user.userId);
  }

  // ... vos autres routes ...

  // 2. LIKE / DISLIKE
  @Post(':id/favorite')
  @UseGuards(JwtAuthGuard)
  toggleFavorite(@Param('id') id: string, @Request() req: any) {
    return this.annoncesService.toggleFavorite(req.user.userId, +id);
  }
}