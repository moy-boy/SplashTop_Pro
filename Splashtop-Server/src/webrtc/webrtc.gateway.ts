import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

interface Client {
  id: string;
  type: 'client' | 'streamer';
  userId?: string;
  deviceId?: string;
  socket: Socket;
}

interface WebRTCMessage {
  type: string;
  from?: string;
  to?: string;
  offer?: any;
  answer?: any;
  candidate?: any;
  target?: string;
}

@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class WebRTCGateway {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(WebRTCGateway.name);
  private clients: Map<string, Client> = new Map();
  private streamers: Map<string, Client> = new Map();

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
    
    // Remove from clients map
    this.clients.delete(client.id);
    
    // Remove from streamers map
    this.streamers.delete(client.id);
  }

  @SubscribeMessage('register')
  handleRegister(
    @MessageBody() data: { type: string; userId?: string; deviceId?: string },
    @ConnectedSocket() client: Socket,
  ) {
    const clientInfo: Client = {
      id: client.id,
      type: data.type as 'client' | 'streamer',
      userId: data.userId,
      deviceId: data.deviceId,
      socket: client,
    };

    this.clients.set(client.id, clientInfo);

    if (data.type === 'streamer' && data.deviceId) {
      this.streamers.set(data.deviceId, clientInfo);
      this.logger.log(`Streamer registered: ${data.deviceId}`);
      
      // Notify clients that streamer is available
      this.server.emit('streamer-available', {
        deviceId: data.deviceId,
        capabilities: {
          video: true,
          audio: false,
          input: true,
        },
      });
    } else if (data.type === 'client') {
      this.logger.log(`Client registered: ${data.userId}`);
      
      // Send available streamers to client
      const availableStreamers = Array.from(this.streamers.keys());
      client.emit('available-streamers', availableStreamers);
    }
  }

  @SubscribeMessage('connect-request')
  handleConnectRequest(
    @MessageBody() data: { streamerId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const clientInfo = this.clients.get(client.id);
    if (!clientInfo || clientInfo.type !== 'client') {
      return;
    }

    const streamer = this.streamers.get(data.streamerId);
    if (!streamer) {
      client.emit('error', { message: 'Streamer not found' });
      return;
    }

    this.logger.log(`Client ${clientInfo.userId} requesting connection to streamer ${data.streamerId}`);
    
    // Notify streamer about connection request
    streamer.socket.emit('client-connect-request', {
      clientId: client.id,
      userId: clientInfo.userId,
    });
  }

  @SubscribeMessage('offer')
  handleOffer(
    @MessageBody() data: WebRTCMessage,
    @ConnectedSocket() client: Socket,
  ) {
    const target = data.target;
    if (!target) {
      return;
    }

    const targetClient = this.clients.get(target) || this.streamers.get(target);
    if (!targetClient) {
      client.emit('error', { message: 'Target not found' });
      return;
    }

    this.logger.log(`Forwarding offer from ${client.id} to ${target}`);
    
    targetClient.socket.emit('offer', {
      offer: data.offer,
      from: client.id,
    });
  }

  @SubscribeMessage('answer')
  handleAnswer(
    @MessageBody() data: WebRTCMessage,
    @ConnectedSocket() client: Socket,
  ) {
    const target = data.target;
    if (!target) {
      return;
    }

    const targetClient = this.clients.get(target) || this.streamers.get(target);
    if (!targetClient) {
      client.emit('error', { message: 'Target not found' });
      return;
    }

    this.logger.log(`Forwarding answer from ${client.id} to ${target}`);
    
    targetClient.socket.emit('answer', {
      answer: data.answer,
      from: client.id,
    });
  }

  @SubscribeMessage('ice-candidate')
  handleIceCandidate(
    @MessageBody() data: WebRTCMessage,
    @ConnectedSocket() client: Socket,
  ) {
    const target = data.target;
    if (!target) {
      return;
    }

    const targetClient = this.clients.get(target) || this.streamers.get(target);
    if (!targetClient) {
      client.emit('error', { message: 'Target not found' });
      return;
    }

    this.logger.log(`Forwarding ICE candidate from ${client.id} to ${target}`);
    
    targetClient.socket.emit('ice-candidate', {
      candidate: data.candidate,
      from: client.id,
    });
  }

  @SubscribeMessage('input-event')
  handleInputEvent(
    @MessageBody() data: any,
    @ConnectedSocket() client: Socket,
  ) {
    const target = data.target;
    if (!target) {
      return;
    }

    const targetClient = this.clients.get(target) || this.streamers.get(target);
    if (!targetClient) {
      return;
    }

    // Forward input event to streamer
    targetClient.socket.emit('input-event', {
      type: data.type,
      action: data.action,
      x: data.x,
      y: data.y,
      key: data.key,
      text: data.text,
      timestamp: data.timestamp,
    });
  }

  @SubscribeMessage('start-streaming')
  handleStartStreaming(
    @MessageBody() data: { deviceId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const streamer = this.streamers.get(data.deviceId);
    if (!streamer) {
      client.emit('error', { message: 'Streamer not found' });
      return;
    }

    this.logger.log(`Starting streaming for device: ${data.deviceId}`);
    
    streamer.socket.emit('start-streaming', {
      clientId: client.id,
    });
  }

  @SubscribeMessage('stop-streaming')
  handleStopStreaming(
    @MessageBody() data: { deviceId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const streamer = this.streamers.get(data.deviceId);
    if (!streamer) {
      return;
    }

    this.logger.log(`Stopping streaming for device: ${data.deviceId}`);
    
    streamer.socket.emit('stop-streaming', {
      clientId: client.id,
    });
  }

  // Get available streamers
  getAvailableStreamers(): string[] {
    return Array.from(this.streamers.keys());
  }

  // Get client info
  getClientInfo(clientId: string): Client | undefined {
    return this.clients.get(clientId);
  }

  // Get streamer info
  getStreamerInfo(deviceId: string): Client | undefined {
    return this.streamers.get(deviceId);
  }
}
