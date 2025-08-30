import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get('health')
  getHealth() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'SplashTop Backend Server',
      version: '1.0.0'
    };
  }

  @Get()
  getInfo() {
    return {
      name: 'SplashTop Backend Server',
      version: '1.0.0',
      description: 'Remote desktop signaling and relay server',
      endpoints: {
        health: '/health',
        auth: '/auth',
        users: '/users',
        streamers: '/streamers',
        webrtc: '/webrtc'
      }
    };
  }
}
