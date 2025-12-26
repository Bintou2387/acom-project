import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { UsersModule } from '../users/users.module';
import { JwtModule } from '@nestjs/jwt';
import { jwtConstants } from './constants';
import { JwtStrategy } from './jwt.strategy';

@Module({
  imports: [
    UsersModule, // On a besoin des Users
    JwtModule.register({
      global: true,
      secret: jwtConstants.secret,
      signOptions: { expiresIn: '60d' }, // Le token dure 60 jours
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy], // On déclare le service et le gardien
  exports: [AuthService],
})
export class AuthModule {}