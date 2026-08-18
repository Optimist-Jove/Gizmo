import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { MessagesService } from '../modules/messages/messages.service';
import { MessageStatus, SecurityLevel } from '../entities/message.entity';

@WebSocketGateway({ cors: { origin: '*' } })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private connectedUsers = new Map<string, string>(); // userId -> socketId

  constructor(private readonly messagesService: MessagesService) {}

  handleConnection(client: Socket) {
    const userId = client.handshake.query.userId as string;
    if (userId) {
      this.connectedUsers.set(userId, client.id);
      client.join(`user_${userId}`);
      console.log(`[WebSocket] User connected: ${userId} (socket ${client.id})`);
      this.server.emit('presence:update', { userId, status: 'ONLINE' });
    }
  }

  handleDisconnect(client: Socket) {
    for (const [userId, socketId] of this.connectedUsers.entries()) {
      if (socketId === client.id) {
        this.connectedUsers.delete(userId);
        console.log(`[WebSocket] User disconnected: ${userId}`);
        this.server.emit('presence:update', { userId, status: 'OFFLINE' });
        break;
      }
    }
  }

  @SubscribeMessage('message:send')
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    payload: {
      senderId: string;
      receiverId: string;
      ciphertext: string;
      securityLevel: SecurityLevel;
      nonce?: string;
      authTag?: string;
      ephemeralPublicKey?: string;
    },
  ) {
    const message = await this.messagesService.createMessage(
      payload.senderId,
      payload.receiverId,
      payload.ciphertext,
      payload.securityLevel,
      payload.nonce,
      payload.authTag,
      payload.ephemeralPublicKey,
    );

    // Relay to receiver socket room
    this.server.to(`user_${payload.receiverId}`).emit('message:receive', message);

    // Confirm SENT status back to sender
    client.emit('message:sent_ack', message);

    return message;
  }

  @SubscribeMessage('message:status')
  async handleStatusUpdate(
    @MessageBody() payload: { messageId: string; senderId: string; status: MessageStatus },
  ) {
    const updated = await this.messagesService.updateMessageStatus(payload.messageId, payload.status);
    this.server.to(`user_${payload.senderId}`).emit('message:status_ack', {
      messageId: payload.messageId,
      status: payload.status,
    });
    return updated;
  }

  @SubscribeMessage('typing:start')
  handleTypingStart(@MessageBody() payload: { senderId: string; receiverId: string }) {
    this.server.to(`user_${payload.receiverId}`).emit('typing:update', { senderId: payload.senderId, isTyping: true });
  }

  @SubscribeMessage('typing:stop')
  handleTypingStop(@MessageBody() payload: { senderId: string; receiverId: string }) {
    this.server.to(`user_${payload.receiverId}`).emit('typing:update', { senderId: payload.senderId, isTyping: false });
  }
}
