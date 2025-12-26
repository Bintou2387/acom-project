import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { ServeStaticModule } from '@nestjs/serve-static'; // <--- IMPORT AJOUTÉ
import { join } from 'path'; // <--- IMPORT AJOUTÉ
import { AnnoncesModule } from './annonces/annonces.module';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { MessagesModule } from './messages/messages.module'; // <--- IMPORT
import { Message } from './messages/entities/message.entity'; // <--- IMPORT ENTITY
import { User } from './users/entities/user.entity';
import { Annonce } from './annonces/entities/annonce.entity';

@Module({
  imports: [
    ConfigModule.forRoot(),

    // --- C'EST ICI LA CORRECTION POUR LES IMAGES ---
    ServeStaticModule.forRoot({
      rootPath: join(process.cwd(), 'uploads'), // Dit au serveur : "Les images sont dans le dossier uploads"
      serveRoot: '/', // Dit au serveur : "Sers-les directement (ex: localhost:3000/photo.jpg)"
    }),
    // -----------------------------------------------

    // Connexion Base de Données (NEON.TECH)
    TypeOrmModule.forRoot({
      type: 'postgres',
      // Votre lien magique Neon :
      url: 'postgresql://neondb_owner:npg_kQXMg0vUZ8uP@ep-old-violet-ad2oqkiv-pooler.c-2.us-east-1.aws.neon.tech/neondb?sslmode=require',
      
      entities: [User, Annonce, Message], 
      synchronize: true, // Crée les tables automatiquement
      ssl: true,         // Sécurité obligatoire pour le Cloud
      extra: {
        ssl: { rejectUnauthorized: false },
      },
    }),
    AnnoncesModule,
    UsersModule,
    AuthModule,
    MessagesModule, // <--- AJOUTEZ LE MODULE ICI
  ],
})
export class AppModule {}