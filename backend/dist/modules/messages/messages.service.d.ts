import { Repository } from 'typeorm';
import { Message, MessageStatus, SecurityLevel } from '../../entities/message.entity';
export declare class MessagesService {
    private messageRepository;
    constructor(messageRepository: Repository<Message>);
    createMessage(senderId: string, receiverId: string, ciphertext: string, securityLevel?: SecurityLevel, nonce?: string, authTag?: string, ephemeralPublicKey?: string, protocolVersion?: string): Promise<Message>;
    getConversationHistory(userId: string, contactId: string, limit?: number): Promise<Message[]>;
    updateMessageStatus(messageId: string, status: MessageStatus): Promise<Message>;
}
