import { Controller, Post, Get, Patch, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { MessagesService } from './messages.service';
import { AuthGuard } from '@nestjs/passport';
import { MessageStatus, SecurityLevel } from '../../entities/message.entity';

@Controller('messages')
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  @UseGuards(AuthGuard('jwt'))
  @Post()
  async sendMessage(
    @Request() req,
    @Body()
    body: {
      receiverId: string;
      ciphertext: string;
      securityLevel: SecurityLevel;
      nonce?: string;
      authTag?: string;
      ephemeralPublicKey?: string;
      protocolVersion?: string;
    },
  ) {
    return this.messagesService.createMessage(
      req.user.id,
      body.receiverId,
      body.ciphertext,
      body.securityLevel,
      body.nonce,
      body.authTag,
      body.ephemeralPublicKey,
      body.protocolVersion,
    );
  }

  @UseGuards(AuthGuard('jwt'))
  @Get('history/:contactId')
  async getHistory(@Request() req, @Param('contactId') contactId: string, @Query('limit') limit?: number) {
    return this.messagesService.getConversationHistory(req.user.id, contactId, limit ? Number(limit) : 50);
  }

  @UseGuards(AuthGuard('jwt'))
  @Patch(':id/status')
  async updateStatus(@Param('id') id: string, @Body() body: { status: MessageStatus }) {
    return this.messagesService.updateMessageStatus(id, body.status);
  }
}
