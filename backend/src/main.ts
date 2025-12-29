import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express'; 
import { join } from 'path'; 

async function bootstrap() {
  // On précise <NestExpressApplication> pour avoir accès aux fonctions statiques
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  
  // IMPORTANT : Activer CORS pour que l'app mobile puisse parler au serveur
  app.enableCors(); 

  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true })); 
  
  // --- RENDRE LE DOSSIER UPLOADS PUBLIC ---
  app.useStaticAssets(join(__dirname, '..', 'uploads'), {
    prefix: '/uploads/',
  });
  // ----------------------------------------

  // CORRECTION ICI : On utilise le port de Koyeb (process.env.PORT) sinon 3000
  const port = process.env.PORT || 3000;
  await app.listen(port, '0.0.0.0');
  
  console.log(`L'application tourne sur le port : ${port}`);
}
bootstrap();