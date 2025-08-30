import { Injectable } from '@nestjs/common';
import { Socket } from 'socket.io';

interface ClientInfo {
  socket: Socket;
  type: 'streamer' | 'client';
  userId?: string;
  deviceId?: string;
  streamerId?: string;
}

@Injectable()
export class WebRTCService {
  private clients = new Map<string, ClientInfo>();
  private streamers = new Map<string, ClientInfo>();

  addClient(client: Socket) {
    this.clients.set(client.id, {
      socket: client,
      type: 'client',
    });
  }

  removeClient(client: Socket) {
    this.clients.delete(client.id);
    this.streamers.delete(client.id);
  }

  registerClient(client: Socket, data: { type: 'streamer' | 'client'; userId?: string; deviceId?: string }) {
    const clientInfo: ClientInfo = {
      socket: client,
      type: data.type,
      userId: data.userId,
      deviceId: data.deviceId,
    };

    this.clients.set(client.id, clientInfo);

    if (data.type === 'streamer') {
      this.streamers.set(data.deviceId || client.id, clientInfo);
      console.log(`Streamer registered: ${data.deviceId || client.id}`);
    } else {
      console.log(`Client registered: ${client.id}`);
    }

    return { success: true, clientId: client.id };
  }

  relayOffer(client: Socket, data: { offer: any; target: string }) {
    const targetClient = this.clients.get(data.target);
    if (targetClient) {
      targetClient.socket.emit('offer', {
        offer: data.offer,
        from: client.id,
      });
      return { success: true };
    }
    return { success: false, error: 'Target client not found' };
  }

  relayAnswer(client: Socket, data: { answer: any; target: string }) {
    const targetClient = this.clients.get(data.target);
    if (targetClient) {
      targetClient.socket.emit('answer', {
        answer: data.answer,
        from: client.id,
      });
      return { success: true };
    }
    return { success: false, error: 'Target client not found' };
  }

  relayIceCandidate(client: Socket, data: { candidate: any; target: string }) {
    const targetClient = this.clients.get(data.target);
    if (targetClient) {
      targetClient.socket.emit('ice-candidate', {
        candidate: data.candidate,
        from: client.id,
      });
      return { success: true };
    }
    return { success: false, error: 'Target client not found' };
  }

  handleConnectRequest(client: Socket, data: { streamerId: string }) {
    const streamer = this.streamers.get(data.streamerId);
    if (streamer) {
      streamer.socket.emit('connect-request', {
        from: client.id,
        userId: this.clients.get(client.id)?.userId,
      });
      return { success: true };
    }
    return { success: false, error: 'Streamer not found' };
  }

  getStreamers() {
    return Array.from(this.streamers.values()).map(streamer => ({
      deviceId: streamer.deviceId,
      userId: streamer.userId,
      socketId: streamer.socket.id,
    }));
  }

  getClientInfo(clientId: string) {
    return this.clients.get(clientId);
  }
}
