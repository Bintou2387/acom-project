import { Entity, Column, PrimaryColumn, OneToOne, JoinColumn } from 'typeorm';
import { Annonce } from './annonce.entity';

@Entity('annonces_hotel')
export class AnnonceHotel {
  @PrimaryColumn()
  annonceId: number;

  @OneToOne(() => Annonce, (annonce) => annonce.id, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'annonceId' })
  annonce: Annonce;

  @Column({ default: 0 })
  stars: number; // Nombre d'étoiles

  @Column({ type: 'time', nullable: true })
  check_in_time: string;

  @Column({ type: 'time', nullable: true })
  check_out_time: string;

  @Column({ default: false })
  has_wifi: boolean;

  @Column({ default: false })
  has_pool: boolean;

  @Column({ default: false })
  has_breakfast: boolean;

  @Column({ default: false })
  has_parking: boolean;
}