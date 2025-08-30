import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { StreamersModule } from './streamers/streamers.module';
import { WebRTCModule } from './webrtc/webrtc.module';
import { User } from './users/entities/user.entity';
import { Streamer } from './streamers/entities/streamer.entity';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT) || 5432,
      username: process.env.DB_USERNAME || 'postgres',
      password: process.env.DB_PASSWORD || 'password',
      database: process.env.DB_NAME || 'splashtop',
      entities: [User, Streamer],
      synchronize: process.env.NODE_ENV !== 'production', // Auto-create tables in development
      logging: process.env.NODE_ENV !== 'production',
    }),
    AuthModule,
    UsersModule,
    StreamersModule,
    WebRTCModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
