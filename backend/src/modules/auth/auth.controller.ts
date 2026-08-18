import { Controller, Post, Body } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('send-otp')
  async sendOtp(@Body() body: { phoneNumber: string }) {
    return this.authService.sendOtp(body.phoneNumber);
  }

  @Post('verify-otp')
  async verifyOtp(@Body() body: { phoneNumber: string; otp: string }) {
    return this.authService.verifyOtp(body.phoneNumber, body.otp);
  }
}
