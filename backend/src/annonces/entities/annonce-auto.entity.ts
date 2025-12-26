import { Entity, Column, PrimaryColumn, OneToOne, JoinColumn } from 'typeorm';
import { Annonce } from './annonce.entity';

export enum FuelType {
  ESSENCE = 'ESSENCE',
  DIESEL = 'DIESEL',
  HYBRIDE = 'HYBRIDE',
  ELECTRIQUE = 'ELECTRIQUE',
}

@Entity('annonces_auto')
export class AnnonceAuto {
  // La clé primaire est aussi la clé étrangère vers la table Annonce
  // Cela garantit la relation "1 annonce = 1 fiche auto"
  @PrimaryColumn()
  annonceId: number;

  @OneToOne(() => Annonce, (annonce) => annonce.id, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'annonceId' })
  annonce: Annonce;

  @Column()
  brand: string; // Marque (ex: Dacia)

  @Column()
  model: string; // Modèle (ex: Logan)

  @Column()
  year: number;

  @Column()
  mileage_km: number;

  @Column({
    type: 'enum',
    enum: FuelType,
  })
  fuel_type: FuelType;

  @Column({ nullable: true })
  gearbox: string; // Manuelle ou Automatique

  @Column({ default: false })
  is_rental: boolean; // Vrai si c'est une location, Faux si c'est une vente
}