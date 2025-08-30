import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Enable CORS for WebRTC connections
  app.enableCors({
    origin: true,
    credentials: true,
  });
  
  // Global validation pipe
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    transform: true,
  }));
  
  const port = process.env.PORT || 3000;
  await app.listen(port);
  
  console.log(`🚀 SplashTop Server running on port ${port}`);
  console.log(`📡 WebSocket signaling available at ws://localhost:${port}`);
  console.log(`🔐 REST API available at http://localhost:${port}`);
  console.log(`📊 Health check: http://localhost:${port}/health`);
}

bootstrap().catch(err => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
