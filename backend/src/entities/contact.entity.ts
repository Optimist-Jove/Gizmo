import { Entity, PrimaryColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('contacts')
export class Contact {
  @PrimaryColumn('uuid')
  ownerId: string;

  @PrimaryColumn('uuid')
  contactId: string;

  @Column({ default: false })
  verified: boolean;

  @Column({ nullable: true })
  safetyNumberHash: string;

  @CreateDateColumn()
  createdAt: Date;
}
