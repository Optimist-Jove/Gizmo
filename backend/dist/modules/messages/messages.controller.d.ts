import { MessagesService } from './messages.service';
import { MessageStatus, SecurityLevel } from '../../entities/message.entity';
export declare class MessagesController {
    private readonly messagesService;
    constructor(messagesService: MessagesService);
    sendMessage(req: any, body: {
        receiverId: string;
        ciphertext: string;
        securityLevel: SecurityLevel;
        nonce?: string;
        authTag?: string;
        ephemeralPublicKey?: string;
        protocolVersion?: string;
    }): Promise<import("../../entities/message.entity").Message>;
    getHistory(req: any, contactId: string, limit?: number): Promise<import("../../entities/message.entity").Message[]>;
    updateStatus(id: string, body: {
        status: MessageStatus;
    }): Promise<import("../../entities/message.entity").Message>;
}
