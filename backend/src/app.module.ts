import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule } from '@nestjs/config';

import { User } from './entities/user.entity';
import { Message } from './entities/message.entity';
import { Contact } from './entities/contact.entity';

import { AuthService } from './modules/auth/auth.service';
import { AuthController } from './modules/auth/auth.controller';
import { JwtStrategy } from './modules/auth/jwt.strategy';

import { UsersService } from './modules/users/users.service';
import { UsersController } from './modules/users/users.controller';

import { MessagesService } from './modules/messages/messages.service';
import { MessagesController } from './modules/messages/messages.controller';

import { ChatGateway } from './gateways/chat.gateway';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'sqlite',
      database: 'gizmo.sqlite',
      entities: [User, Message, Contact],
      synchronize: true,
    }),
    TypeOrmModule.forFeature([User, Message, Contact]),
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'gizmo-super-secret-jwt-key-2026',
      signOptions: { expiresIn: '30d' },
    }),
  ],
  controllers: [AuthController, UsersController, MessagesController],
  providers: [AuthService, JwtStrategy, UsersService, MessagesService, ChatGateway],
})
export class AppModule {}
