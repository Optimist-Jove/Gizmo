import { JwtService } from '@nestjs/jwt';
import { Repository } from 'typeorm';
import { User } from '../../entities/user.entity';
export declare class AuthService {
    private userRepository;
    private jwtService;
    constructor(userRepository: Repository<User>, jwtService: JwtService);
    sendOtp(phoneNumber: string): Promise<{
        success: boolean;
        message: string;
        debugOtp?: string;
    }>;
    verifyOtp(phoneNumber: string, otp: string): Promise<{
        accessToken: string;
        isRegistered: boolean;
        user?: User;
    }>;
}
