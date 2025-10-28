// services/changeStream.js
import mongoose from 'mongoose';
import { Timestamp } from 'bson'; // <- thêm dòng này
import { Message } from '../models/Message.js';
import { broadcastToConversation } from './ws.js';

export function startMessageChangeStream() {
  const pipeline = [{ $match: { operationType: { $in: ['insert'] } } }];

  // Sửa cách tạo Timestamp: dùng object { t, i }
  const startAt = new Timestamp({ t: Math.floor(Date.now() / 1000), i: 1 });

  const opts = {
    fullDocument: 'updateLookup',
    startAtOperationTime: startAt, // <- dùng biến startAt
  };

  const cs = Message.watch(pipeline, opts);

  cs.on('change', (change) => {
    const msg = change.fullDocument;
    if (!msg) return;

    const convoId = msg.conversationId.toString();
    broadcastToConversation(convoId, {
      type: 'message',
      conversationId: convoId,
      message: {
        _id: msg._id,
        clientMessageId: msg.clientMessageId,
        senderId: msg.senderId,
        kind: msg.kind,
        text: msg.text,
        media: msg.media,
        captions: msg.captions,
        timestamp: msg.timestamp,
      },
    });
  });

  cs.on('error', (err) => {
    console.error('[CS] error', err.message);
    setTimeout(startMessageChangeStream, 1000);
  });

  cs.on('close', () => {
    console.warn('[CS] closed. Reopening…');
    setTimeout(startMessageChangeStream, 1000);
  });

  console.log('[CS] started for messages');
}
