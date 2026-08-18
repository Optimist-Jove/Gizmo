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
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const user_entity_1 = require("../../entities/user.entity");
const otpStore = new Map();
let AuthService = class AuthService {
    userRepository;
    jwtService;
    constructor(userRepository, jwtService) {
        this.userRepository = userRepository;
        this.jwtService = jwtService;
    }
    async sendOtp(phoneNumber) {
        if (!phoneNumber || !phoneNumber.startsWith('+')) {
            throw new common_1.BadRequestException('Phone number must be in E.164 format (e.g. +1234567890)');
        }
        const code = process.env.NODE_ENV === 'production' ? Math.floor(100000 + Math.random() * 900000).toString() : '123456';
        const expiresAt = Date.now() + 10 * 60 * 1000;
        otpStore.set(phoneNumber, { code, expiresAt });
        return {
            success: true,
            message: `OTP sent to ${phoneNumber}`,
            debugOtp: code,
        };
    }
    async verifyOtp(phoneNumber, otp) {
        const record = otpStore.get(phoneNumber);
        if (!record || record.code !== otp || Date.now() > record.expiresAt) {
            throw new common_1.BadRequestException('Invalid or expired OTP code');
        }
        otpStore.delete(phoneNumber);
        let user = await this.userRepository.findOne({ where: { phoneNumber } });
        const isRegistered = !!(user && user.displayName && user.publicKey);
        if (!user) {
            user = this.userRepository.create({ phoneNumber });
            await this.userRepository.save(user);
        }
        const payload = { sub: user.id, phoneNumber: user.phoneNumber };
        const accessToken = this.jwtService.sign(payload);
        return {
            accessToken,
            isRegistered,
            user,
        };
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        jwt_1.JwtService])
], AuthService);
//# sourceMappingURL=auth.service.js.map