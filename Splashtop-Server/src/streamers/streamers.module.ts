import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { StreamersController } from './streamers.controller';
import { StreamersService } from './streamers.service';
import { Streamer } from './entities/streamer.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Streamer])],
  controllers: [StreamersController],
  providers: [StreamersService],
  exports: [StreamersService],
})
export class StreamersModule {}
