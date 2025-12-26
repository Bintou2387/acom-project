import { Injectable, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private usersRepository: Repository<User>,
  ) {}

  // INSCRIPTION
  async create(createUserDto: any) {
    // 1. Vérif email
    const existingUser = await this.usersRepository.findOneBy({ email: createUserDto.email });
    if (existingUser) {
      throw new ConflictException('Cet email est déjà utilisé');
    }

    // 2. Hachage
    const salt = await bcrypt.genSalt();
    const hashedPassword = await bcrypt.hash(createUserDto.password, salt);

    // 3. Création
    const newUser = this.usersRepository.create({
      ...createUserDto,
      password: hashedPassword,
    });

    // 4. Sauvegarde
    // On force le typage "as any" ici pour contourner l'erreur TS2339 (le compilateur qui pense que c'est un tableau)
    const savedUser = await this.usersRepository.save(newUser);
    const { password, ...result } = (savedUser as any);
    
    return result;
  }

  // TROUVER PAR EMAIL
  // J'ai retiré le ": Promise<User | undefined>" pour laisser TypeScript deviner tout seul (il trouvera "User | null")
  async findOneByEmail(email: string) {
    return this.usersRepository.findOneBy({ email });
  }

  findAll() {
    return this.usersRepository.find();
  }
  // ... vos autres méthodes (create, findOne, etc.) ...

  // AJOUTEZ CECI :
  async update(id: number, attrs: Partial<User>) {
    // On utilise le repository pour mettre à jour
    return this.usersRepository.update(id, attrs);
  }
} // Fin de la classe
