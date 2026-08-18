import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  phoneNumber: string;

  @Column({ nullable: true })
  displayName: string;

  @Column({ nullable: true })
  avatarUrl: string;

  @Column({ nullable: true })
  about: string;

  @Column({ type: 'text', nullable: true })
  publicKey: string;

  @Column({ default: 1 })
  publicKeyVersion: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
