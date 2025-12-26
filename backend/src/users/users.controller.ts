import { Controller, Post, Body, Get, Param, UseGuards, Request, UseInterceptors, UploadedFile } from '@nestjs/common';
import { UsersService } from './users.service';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // Assurez-vous que le chemin est bon

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('signup')
  create(@Body() createUserDto: any) {
    return this.usersService.create(createUserDto);
  }

  @Get()
  findAll() {
    return this.usersService.findAll();
  }

  @Get(':id/promote')
  async promoteToAdmin(@Param('id') id: string) {
    await this.usersService.update(+id, { role: 'admin' });
    return { message: "L'utilisateur est maintenant ADMINISTRATEUR 👮‍♂️" };
  }

  // --- NOUVELLE ROUTE : UPLOAD PHOTO DE PROFIL ---
  @Post('upload')
  @UseGuards(JwtAuthGuard) // Il faut être connecté
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: './uploads', // On stocke au même endroit que les annonces
      filename: (req, file, callback) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
        const ext = extname(file.originalname);
        callback(null, `avatar-${uniqueSuffix}${ext}`);
      },
    }),
  }))
  async uploadAvatar(@UploadedFile() file: Express.Multer.File, @Request() req) {
    // req.user.userId vient du Token JWT
    // On met à jour l'utilisateur avec le nom du fichier
    await this.usersService.update(req.user.userId, { profilePicture: file.filename });
    return { filename: file.filename };
  }
}