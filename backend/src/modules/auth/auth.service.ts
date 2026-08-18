import { Injectable, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../entities/user.entity';

// In-memory OTP storage for development & testing (or replace with Redis/Twilio)
const otpStore = new Map<string, { code: string; expiresAt: number }>();

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private jwtService: JwtService,
  ) {}

  async sendOtp(phoneNumber: string): Promise<{ success: boolean; message: string; debugOtp?: string }> {
    if (!phoneNumber || !phoneNumber.startsWith('+')) {
      throw new BadRequestException('Phone number must be in E.164 format (e.g. +1234567890)');
    }

    // Generate 6-digit OTP code (default test code '123456' for convenience)
    const code = process.env.NODE_ENV === 'production' ? Math.floor(100000 + Math.random() * 900000).toString() : '123456';
    const expiresAt = Date.now() + 10 * 60 * 1000; // 10 minutes expiry

    otpStore.set(phoneNumber, { code, expiresAt });

    return {
      success: true,
      message: `OTP sent to ${phoneNumber}`,
      debugOtp: code,
    };
  }

  async verifyOtp(phoneNumber: string, otp: string): Promise<{ accessToken: string; isRegistered: boolean; user?: User }> {
    const record = otpStore.get(phoneNumber);
    if (!record || record.code !== otp || Date.now() > record.expiresAt) {
      throw new BadRequestException('Invalid or expired OTP code');
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
}
