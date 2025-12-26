import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  // Vérifie l'email et le mot de passe
  async validateUser(email: string, pass: string): Promise<any> {
    const user = await this.usersService.findOneByEmail(email);
    
    // Si l'user existe ET que le mot de passe correspond au hash
    if (user && (await bcrypt.compare(pass, user.password))) {
      // On retire le mot de passe du résultat pour la sécurité
      const { password, ...result } = user;
      return result;
    }
    return null;
  }

  // Génère le Token
  async login(user: any) {
    const payload = { username: user.email, sub: user.id };
    return {
      access_token: this.jwtService.sign(payload),
      user_id: user.id,
      name: user.fullName,
      role: user.role, // <--- ON AJOUTE CECI (Le plus important)
    };
  }
}