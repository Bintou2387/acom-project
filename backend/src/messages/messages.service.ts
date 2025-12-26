import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message } from './entities/message.entity';
import { User } from '../users/entities/user.entity';

@Injectable()
export class MessagesService {
  constructor(
    @InjectRepository(Message)
    private messagesRepository: Repository<Message>,
  ) {}

  // 1. ENVOYER UN MESSAGE
  async sendMessage(senderId: number, receiverId: number, content: string) {
    const message = this.messagesRepository.create({
      content,
      sender: { id: senderId } as User,
      receiver: { id: receiverId } as User,
    });
    return await this.messagesRepository.save(message);
  }

  // 2. LIRE LA CONVERSATION AVEC QUELQU'UN
  // On veut les messages où (Moi -> Lui) OU (Lui -> Moi)
  async getConversation(myId: number, otherUserId: number) {
    return this.messagesRepository.find({
      where: [
        { sender: { id: myId }, receiver: { id: otherUserId } },
        { sender: { id: otherUserId }, receiver: { id: myId } }
      ],
      order: { createdAt: 'ASC' }, // Du plus vieux au plus récent
    });
  }

  // 3. (BONUS) LISTE DE MES CONTACTS (Ceux avec qui j'ai parlé)
  // C'est une requête SQL complexe, on verra plus tard si besoin.
  // Pour l'instant on passera par l'annonce pour contacter le vendeur.
}