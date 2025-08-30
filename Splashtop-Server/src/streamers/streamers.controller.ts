import { Controller, Get, Post, Body, UseGuards, Request } from '@nestjs/common';
import { StreamersService } from './streamers.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { StreamerPlatform } from './entities/streamer.entity';

@Controller('streamers')
@UseGuards(JwtAuthGuard)
export class StreamersController {
  constructor(private streamersService: StreamersService) {}

  @Get('my-pcs')
  async getMyPCs(@Request() req) {
    return this.streamersService.findByUserId(req.user.id);
  }

  @Get()
  async findAll() {
    return this.streamersService.findAll();
  }

  @Post('register')
  async registerStreamer(
    @Body() createStreamerDto: {
      name: string;
      deviceId: string;
      platform: StreamerPlatform;
      capabilities?: any;
    },
    @Request() req,
  ) {
    return this.streamersService.create({
      ...createStreamerDto,
      userId: req.user.id,
    });
  }
}
