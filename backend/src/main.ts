import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express'; // <--- IMPORT
import { join } from 'path'; // <--- IMPORT

async function bootstrap() {
  // On précise <NestExpressApplication> pour avoir accès aux fonctions statiques
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  
  app.useGlobalPipes(new ValidationPipe({ transform: true, whitelist: true })); 
  
  // --- RENDRE LE DOSSIER UPLOADS PUBLIC ---
  app.useStaticAssets(join(__dirname, '..', 'uploads'), {
    prefix: '/uploads/',
  });
  // ----------------------------------------

  await app.listen(3000, '0.0.0.0');
}
bootstrap();