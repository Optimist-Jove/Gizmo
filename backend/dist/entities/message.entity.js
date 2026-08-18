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
Object.defineProperty(exports, "__esModule", { value: true });
exports.Message = exports.SecurityLevel = exports.MessageStatus = void 0;
const typeorm_1 = require("typeorm");
var MessageStatus;
(function (MessageStatus) {
    MessageStatus["SENT"] = "SENT";
    MessageStatus["DELIVERED"] = "DELIVERED";
    MessageStatus["READ"] = "READ";
})(MessageStatus || (exports.MessageStatus = MessageStatus = {}));
var SecurityLevel;
(function (SecurityLevel) {
    SecurityLevel["STANDARD"] = "STANDARD";
    SecurityLevel["HIGH"] = "HIGH";
    SecurityLevel["MAXIMUM"] = "MAXIMUM";
    SecurityLevel["NONE"] = "NONE";
})(SecurityLevel || (exports.SecurityLevel = SecurityLevel = {}));
let Message = class Message {
    id;
    senderId;
    receiverId;
    ciphertext;
    securityLevel;
    protocolVersion;
    ephemeralPublicKey;
    nonce;
    authTag;
    status;
    createdAt;
};
exports.Message = Message;
__decorate([
    (0, typeorm_1.PrimaryGeneratedColumn)('uuid'),
    __metadata("design:type", String)
], Message.prototype, "id", void 0);
__decorate([
    (0, typeorm_1.Index)(),
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], Message.prototype, "senderId", void 0);
__decorate([
    (0, typeorm_1.Index)(),
    (0, typeorm_1.Column)(),
    __metadata("design:type", String)
], Message.prototype, "receiverId", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text' }),
    __metadata("design:type", String)
], Message.prototype, "ciphertext", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', default: SecurityLevel.STANDARD }),
    __metadata("design:type", String)
], Message.prototype, "securityLevel", void 0);
__decorate([
    (0, typeorm_1.Column)({ default: '1.0' }),
    __metadata("design:type", String)
], Message.prototype, "protocolVersion", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], Message.prototype, "ephemeralPublicKey", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], Message.prototype, "nonce", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', nullable: true }),
    __metadata("design:type", String)
], Message.prototype, "authTag", void 0);
__decorate([
    (0, typeorm_1.Column)({ type: 'text', default: MessageStatus.SENT }),
    __metadata("design:type", String)
], Message.prototype, "status", void 0);
__decorate([
    (0, typeorm_1.CreateDateColumn)(),
    __metadata("design:type", Date)
], Message.prototype, "createdAt", void 0);
exports.Message = Message = __decorate([
    (0, typeorm_1.Entity)('messages')
], Message);
//# sourceMappingURL=message.entity.js.map