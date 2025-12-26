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

    TypeOrmModule.forRoot({
      type: 'postgres',
      host: 'localhost',
      port: 5435, // Vérifiez que c'est bien votre port (souvent 5432, mais gardez 5435 si c'est votre config)
      username: 'acom_user',
      password: 'acom_password',
      database: 'acom_database',
      autoLoadEntities: true,
      synchronize: true,
      dropSchema: false, // <--- ATTENTION : METTEZ FALSE ! Sinon vous perdez vos données et votre rôle Admin à chaque fois.
      entities: [User, Annonce, Message], // <--- AJOUTEZ MESSAGE ICI !!
    }),
    AnnoncesModule,
    UsersModule,
    AuthModule,
    MessagesModule, // <--- AJOUTEZ LE MODULE ICI
  ],
})
export class AppModule {}