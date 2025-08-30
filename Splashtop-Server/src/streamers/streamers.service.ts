import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Streamer, StreamerStatus, StreamerPlatform } from './entities/streamer.entity';

@Injectable()
export class StreamersService {
  constructor(
    @InjectRepository(Streamer)
    private streamerRepository: Repository<Streamer>,
  ) {}

  async create(createStreamerDto: {
    name: string;
    deviceId: string;
    platform: StreamerPlatform;
    userId: string;
    capabilities?: any;
  }): Promise<Streamer> {
    const streamer = this.streamerRepository.create({
      ...createStreamerDto,
      status: StreamerStatus.OFFLINE,
    });
    return this.streamerRepository.save(streamer);
  }

  async findByUserId(userId: string): Promise<Streamer[]> {
    return this.streamerRepository.find({
      where: { userId },
      relations: ['user'],
    });
  }

  async findByDeviceId(deviceId: string): Promise<Streamer | null> {
    return this.streamerRepository.findOne({
      where: { deviceId },
      relations: ['user'],
    });
  }

  async updateStatus(deviceId: string, status: StreamerStatus, ipAddress?: string): Promise<void> {
    await this.streamerRepository.update(
      { deviceId },
      { 
        status, 
        ipAddress,
        lastSeen: new Date(),
      }
    );
  }

  async findAll(): Promise<Streamer[]> {
    return this.streamerRepository.find({
      relations: ['user'],
    });
  }
}
