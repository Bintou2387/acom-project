import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AnnoncesService } from './annonces.service';
import { AnnoncesController } from './annonces.controller';
import { Annonce } from './entities/annonce.entity';
import { AnnonceAuto } from './entities/annonce-auto.entity';
import { AnnonceImmo } from './entities/annonce-immo.entity';
import { AnnonceHotel } from './entities/annonce-hotel.entity';
import { User } from '../users/entities/user.entity';

@Module({
  // C'est ici qu'on injecte les tables pour pouvoir les utiliser dans le Service
  imports: [
    TypeOrmModule.forFeature([Annonce, AnnonceAuto, AnnonceImmo, AnnonceHotel , User ])
  ],
  controllers: [AnnoncesController],
  providers: [AnnoncesService],
})
export class AnnoncesModule {}