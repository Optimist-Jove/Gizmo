import { UsersService } from './users.service';
export declare class UsersController {
    private readonly usersService;
    constructor(usersService: UsersService);
    register(req: any, body: {
        displayName: string;
        publicKey: string;
        avatarUrl?: string;
        about?: string;
    }): Promise<import("../../entities/user.entity").User>;
    getMe(req: any): Promise<import("../../entities/user.entity").User>;
    updateMe(req: any, body: any): Promise<import("../../entities/user.entity").User>;
    resolveByPhone(phone: string): Promise<import("../../entities/user.entity").User>;
    getPublicKey(id: string): Promise<{
        userId: string;
        publicKey: string;
        version: number;
    }>;
    getAllUsers(): Promise<import("../../entities/user.entity").User[]>;
}
