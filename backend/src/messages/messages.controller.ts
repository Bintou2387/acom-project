import { Controller, Get, Post, Body, Param, UseGuards, Request } from '@nestjs/common';
import { MessagesService } from './messages.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('messages')
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  // ENVOYER : POST /messages
  // Body : { "receiverId": 5, "content": "Salut, dispo ?" }
  @UseGuards(JwtAuthGuard)
  @Post()
  sendMessage(@Request() req, @Body() body: any) {
    return this.messagesService.sendMessage(req.user.userId, body.receiverId, body.content);
  }

  // LIRE : GET /messages/conversation/5
  // (Lire ma discussion avec l'utilisateur ID 5)
  @UseGuards(JwtAuthGuard)
  @Get('conversation/:contactId')
  getConversation(@Request() req, @Param('contactId') contactId: string) {
    return this.messagesService.getConversation(req.user.userId, +contactId);
  }
}