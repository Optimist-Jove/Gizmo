import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {}

  async register(userId: string, displayName: string, publicKey: string, avatarUrl?: string, about?: string): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    user.displayName = displayName;
    user.publicKey = publicKey;
    if (avatarUrl) user.avatarUrl = avatarUrl;
    if (about) user.about = about;

    return await this.userRepository.save(user);
  }

  async getProfile(userId: string): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async updateProfile(userId: string, updates: Partial<User>): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    Object.assign(user, updates);
    return await this.userRepository.save(user);
  }

  async resolveByPhone(phoneNumber: string): Promise<User> {
    const user = await this.userRepository.findOne({ where: { phoneNumber } });
    if (!user) throw new NotFoundException(`User with phone ${phoneNumber} not found`);
    return user;
  }

  async getPublicKey(userId: string): Promise<{ userId: string; publicKey: string; version: number }> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user || !user.publicKey) throw new NotFoundException('User public key not found');
    return {
      userId: user.id,
      publicKey: user.publicKey,
      version: user.publicKeyVersion,
    };
  }

  async findAllUsers(): Promise<User[]> {
    return await this.userRepository.find();
  }
}
