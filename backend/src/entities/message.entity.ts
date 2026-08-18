import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from 'typeorm';

export enum MessageStatus {
  SENT = 'SENT',
  DELIVERED = 'DELIVERED',
  READ = 'READ',
}

export enum SecurityLevel {
  STANDARD = 'STANDARD',
  HIGH = 'HIGH',
  MAXIMUM = 'MAXIMUM',
  NONE = 'NONE',
}

@Entity('messages')
export class Message {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column()
  senderId: string;

  @Index()
  @Column()
  receiverId: string;

  @Column({ type: 'text' })
  ciphertext: string;

  @Column({ type: 'text', default: SecurityLevel.STANDARD })
  securityLevel: SecurityLevel;

  @Column({ default: '1.0' })
  protocolVersion: string;

  @Column({ type: 'text', nullable: true })
  ephemeralPublicKey: string;

  @Column({ type: 'text', nullable: true })
  nonce: string;

  @Column({ type: 'text', nullable: true })
  authTag: string;

  @Column({ type: 'text', default: MessageStatus.SENT })
  status: MessageStatus;

  @CreateDateColumn()
  createdAt: Date;
}
