import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message, MessageStatus, SecurityLevel } from '../../entities/message.entity';

@Injectable()
export class MessagesService {
  constructor(
    @InjectRepository(Message)
    private messageRepository: Repository<Message>,
  ) {}

  async createMessage(
    senderId: string,
    receiverId: string,
    ciphertext: string,
    securityLevel: SecurityLevel = SecurityLevel.STANDARD,
    nonce?: string,
    authTag?: string,
    ephemeralPublicKey?: string,
    protocolVersion = '1.0',
  ): Promise<Message> {
    const message = this.messageRepository.create({
      senderId,
      receiverId,
      ciphertext,
      securityLevel,
      nonce,
      authTag,
      ephemeralPublicKey,
      protocolVersion,
      status: MessageStatus.SENT,
    });

    return await this.messageRepository.save(message);
  }

  async getConversationHistory(userId: string, contactId: string, limit = 50): Promise<Message[]> {
    return await this.messageRepository.find({
      where: [
        { senderId: userId, receiverId: contactId },
        { senderId: contactId, receiverId: userId },
      ],
      order: { createdAt: 'ASC' },
      take: limit,
    });
  }

  async updateMessageStatus(messageId: string, status: MessageStatus): Promise<Message> {
    const message = await this.messageRepository.findOne({ where: { id: messageId } });
    if (!message) throw new NotFoundException('Message not found');

    message.status = status;
    return await this.messageRepository.save(message);
  }
}
