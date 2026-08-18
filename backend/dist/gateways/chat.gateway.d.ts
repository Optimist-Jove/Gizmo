import { OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { MessagesService } from '../modules/messages/messages.service';
import { MessageStatus, SecurityLevel } from '../entities/message.entity';
export declare class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
    private readonly messagesService;
    server: Server;
    private connectedUsers;
    constructor(messagesService: MessagesService);
    handleConnection(client: Socket): void;
    handleDisconnect(client: Socket): void;
    handleSendMessage(client: Socket, payload: {
        senderId: string;
        receiverId: string;
        ciphertext: string;
        securityLevel: SecurityLevel;
        nonce?: string;
        authTag?: string;
        ephemeralPublicKey?: string;
    }): Promise<import("../entities/message.entity").Message>;
    handleStatusUpdate(payload: {
        messageId: string;
        senderId: string;
        status: MessageStatus;
    }): Promise<import("../entities/message.entity").Message>;
    handleTypingStart(payload: {
        senderId: string;
        receiverId: string;
    }): void;
    handleTypingStop(payload: {
        senderId: string;
        receiverId: string;
    }): void;
}
