import { Controller, Get, Post, Put, Body, Query, Param, UseGuards, Request } from '@nestjs/common';
import { UsersService } from './users.service';
import { AuthGuard } from '@nestjs/passport';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @UseGuards(AuthGuard('jwt'))
  @Post('register')
  async register(
    @Request() req,
    @Body() body: { displayName: string; publicKey: string; avatarUrl?: string; about?: string },
  ) {
    return this.usersService.register(req.user.id, body.displayName, body.publicKey, body.avatarUrl, body.about);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('me')
  async getMe(@Request() req) {
    return this.usersService.getProfile(req.user.id);
  }

  @UseGuards(AuthGuard('jwt'))
  @Put('me')
  async updateMe(@Request() req, @Body() body: any) {
    return this.usersService.updateProfile(req.user.id, body);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('resolve')
  async resolveByPhone(@Query('phone') phone: string) {
    return this.usersService.resolveByPhone(phone);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get(':id/public-key')
  async getPublicKey(@Param('id') id: string) {
    return this.usersService.getPublicKey(id);
  }

  @UseGuards(AuthGuard('jwt'))
  @Get()
  async getAllUsers() {
    return this.usersService.findAllUsers();
  }
}
