import { Entity, Column, PrimaryColumn, OneToOne, JoinColumn } from 'typeorm';
import { Annonce } from './annonce.entity';

export enum ImmoType {
  MAISON = 'MAISON',
  APPARTEMENT = 'APPARTEMENT',
  TERRAIN = 'TERRAIN',
  BUREAU = 'BUREAU',
  COLOCATION = 'COLOCATION',
}

@Entity('annonces_immo')
export class AnnonceImmo {
  @PrimaryColumn()
  annonceId: number;

  @OneToOne(() => Annonce, (annonce) => annonce.id, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'annonceId' })
  annonce: Annonce;

  @Column({
    type: 'enum',
    enum: ImmoType,
  })
  type_bien: ImmoType;

  @Column()
  surface_m2: number;

  @Column({ nullable: true })
  rooms_count: number; // Nombre de pièces

  @Column({ nullable: true })
  floor_number: number; // Étage (0 pour RDC)

  @Column({ default: false })
  has_elevator: boolean;

  @Column({ default: false })
  has_balcony: boolean;

  @Column({ default: true })
  is_rental: boolean; // Vrai = Location, Faux = Vente
}