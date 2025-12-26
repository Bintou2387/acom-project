import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, CreateDateColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity()
export class Message {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  content: string;

  @CreateDateColumn()
  createdAt: Date;

  // Relation : Qui envoie ?
  @ManyToOne(() => User, { eager: true }) 
  sender: User;

  // Relation : Qui reçoit ?
  @ManyToOne(() => User, { eager: true })
  receiver: User;
}