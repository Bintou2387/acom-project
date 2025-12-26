import { Entity, PrimaryGeneratedColumn, Column, OneToMany, ManyToMany, JoinTable } from 'typeorm'; // <--- AJOUTEZ ManyToMany, JoinTable
import { Annonce } from '../../annonces/entities/annonce.entity';

@Entity()
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  email: string;

  @Column()
  password: string;

  @Column()
  fullName: string;

  @Column({ nullable: true })
  phone: string;

  @OneToMany(() => Annonce, (annonce) => annonce.user)
  annonces: Annonce[];

  // --- NOUVEAU : LES FAVORIS ---
  @ManyToMany(() => Annonce)
  @JoinTable() // On met JoinTable d'un seul côté de la relation (souvent le User)
  favorites: Annonce[];

  // ... autres colonnes ...

  @Column({ default: 'user' })
  role: string; // 'user' ou 'admin'

  @Column({ nullable: true })
  profilePicture: string; // Nom du fichier image
}