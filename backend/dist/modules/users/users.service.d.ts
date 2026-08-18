import { Repository } from 'typeorm';
import { User } from '../../entities/user.entity';
export declare class UsersService {
    private userRepository;
    constructor(userRepository: Repository<User>);
    register(userId: string, displayName: string, publicKey: string, avatarUrl?: string, about?: string): Promise<User>;
    getProfile(userId: string): Promise<User>;
    updateProfile(userId: string, updates: Partial<User>): Promise<User>;
    resolveByPhone(phoneNumber: string): Promise<User>;
    getPublicKey(userId: string): Promise<{
        userId: string;
        publicKey: string;
        version: number;
    }>;
    findAllUsers(): Promise<User[]>;
}
