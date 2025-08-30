import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

export enum StreamerStatus {
  OFFLINE = 'offline',
  ONLINE = 'online',
  STREAMING = 'streaming',
}

export enum StreamerPlatform {
  WINDOWS = 'windows',
  MACOS = 'macos',
  LINUX = 'linux',
}

@Entity('streamers')
export class Streamer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ unique: true })
  deviceId: string; // Unique device identifier

  @Column({
    type: 'enum',
    enum: StreamerPlatform,
  })
  platform: StreamerPlatform;

  @Column({
    type: 'enum',
    enum: StreamerStatus,
    default: StreamerStatus.OFFLINE,
  })
  status: StreamerStatus;

  @Column({ nullable: true })
  ipAddress: string;

  @Column({ nullable: true })
  lastSeen: Date;

  @Column({ nullable: true })
  version: string;

  @Column({ type: 'json', nullable: true })
  capabilities: {
    hardwareEncoding: boolean;
    screenCapture: string[];
    inputInjection: string[];
  };

  @ManyToOne(() => User, user => user.streamers)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userId: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
