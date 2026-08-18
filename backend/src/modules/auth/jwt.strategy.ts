import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../entities/user.entity';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET || 'gizmo-super-secret-jwt-key-2026',
    });
  }

  async validate(payload: { sub: string; phoneNumber: string }) {
    const user = await this.userRepository.findOne({ where: { id: payload.sub } });
    if (!user) {
      throw new UnauthorizedException('Invalid user session');
    }
    return user;
  }
}
