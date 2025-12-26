import { Entity, Column, PrimaryGeneratedColumn, ManyToOne, JoinColumn } from 'typeorm'; // <--- J'ai ajouté ManyToOne et JoinColumn ici
import { User } from '../../users/entities/user.entity';

@Entity()
export class Annonce {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  title: string;

  @Column('text')
  description: string;

  @Column('decimal')
  price: number;

  @Column({ default: 'AUTOMOBILE' })
  category: string;

  @Column({ nullable: true })
  currency: string;

  @Column('json', { nullable: true })
  detailsAuto: any;

  @Column('json', { nullable: true })
  detailsImmo: any;

  @Column('json', { nullable: true })
  detailsHotel: any;

  @Column('text', { array: true, nullable: true })
  images: string[];

  @Column({ nullable: true })
  phone_number: string;

  @Column('float', { nullable: true })
  latitude: number;

  @Column('float', { nullable: true })
  longitude: number;

  // Relation vers User
  @ManyToOne(() => User, (user) => user.annonces, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;
  // ... autres colonnes ...

  @Column({ default: false })
  isPromoted: boolean; // Vrai si le client a payé
  // ...
  @Column({ default: 0 })
  views: number; // Compteur de vues
  // ... autres colonnes ...

  @Column({ default: 'jour' })
  pricePeriod: string; // Valeurs possibles : 'jour' ou 'mois'
}