"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ChatGateway = void 0;
const websockets_1 = require("@nestjs/websockets");
const socket_io_1 = require("socket.io");
const messages_service_1 = require("../modules/messages/messages.service");
let ChatGateway = class ChatGateway {
    messagesService;
    server;
    connectedUsers = new Map();
    constructor(messagesService) {
        this.messagesService = messagesService;
    }
    handleConnection(client) {
        const userId = client.handshake.query.userId;
        if (userId) {
            this.connectedUsers.set(userId, client.id);
            client.join(`user_${userId}`);
            console.log(`[WebSocket] User connected: ${userId} (socket ${client.id})`);
            this.server.emit('presence:update', { userId, status: 'ONLINE' });
        }
    }
    handleDisconnect(client) {
        for (const [userId, socketId] of this.connectedUsers.entries()) {
            if (socketId === client.id) {
                this.connectedUsers.delete(userId);
                console.log(`[WebSocket] User disconnected: ${userId}`);
                this.server.emit('presence:update', { userId, status: 'OFFLINE' });
                break;
            }
        }
    }
    async handleSendMessage(client, payload) {
        const message = await this.messagesService.createMessage(payload.senderId, payload.receiverId, payload.ciphertext, payload.securityLevel, payload.nonce, payload.authTag, payload.ephemeralPublicKey);
        this.server.to(`user_${payload.receiverId}`).emit('message:receive', message);
        client.emit('message:sent_ack', message);
        return message;
    }
    async handleStatusUpdate(payload) {
        const updated = await this.messagesService.updateMessageStatus(payload.messageId, payload.status);
        this.server.to(`user_${payload.senderId}`).emit('message:status_ack', {
            messageId: payload.messageId,
            status: payload.status,
        });
        return updated;
    }
    handleTypingStart(payload) {
        this.server.to(`user_${payload.receiverId}`).emit('typing:update', { senderId: payload.senderId, isTyping: true });
    }
    handleTypingStop(payload) {
        this.server.to(`user_${payload.receiverId}`).emit('typing:update', { senderId: payload.senderId, isTyping: false });
    }
};
exports.ChatGateway = ChatGateway;
__decorate([
    (0, websockets_1.WebSocketServer)(),
    __metadata("design:type", socket_io_1.Server)
], ChatGateway.prototype, "server", void 0);
__decorate([
    (0, websockets_1.SubscribeMessage)('message:send'),
    __param(0, (0, websockets_1.ConnectedSocket)()),
    __param(1, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [socket_io_1.Socket, Object]),
    __metadata("design:returntype", Promise)
], ChatGateway.prototype, "handleSendMessage", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('message:status'),
    __param(0, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], ChatGateway.prototype, "handleStatusUpdate", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('typing:start'),
    __param(0, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], ChatGateway.prototype, "handleTypingStart", null);
__decorate([
    (0, websockets_1.SubscribeMessage)('typing:stop'),
    __param(0, (0, websockets_1.MessageBody)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], ChatGateway.prototype, "handleTypingStop", null);
exports.ChatGateway = ChatGateway = __decorate([
    (0, websockets_1.WebSocketGateway)({ cors: { origin: '*' } }),
    __metadata("design:paramtypes", [messages_service_1.MessagesService])
], ChatGateway);
//# sourceMappingURL=chat.gateway.js.map