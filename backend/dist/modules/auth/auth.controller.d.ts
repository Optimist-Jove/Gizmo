import { AuthService } from './auth.service';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    sendOtp(body: {
        phoneNumber: string;
    }): Promise<{
        success: boolean;
        message: string;
        debugOtp?: string;
    }>;
    verifyOtp(body: {
        phoneNumber: string;
        otp: string;
    }): Promise<{
        accessToken: string;
        isRegistered: boolean;
        user?: import("../../entities/user.entity").User;
    }>;
}
