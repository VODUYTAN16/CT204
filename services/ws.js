// ws.js
import { WebSocketServer } from 'ws';
import { User } from '../models/User.js'; // ⬅️ thêm import

let _wss = null;
export function createWsServer(httpServer) {
  _wss = new WebSocketServer({ server: httpServer });

  _wss.on('connection', (ws) => {
    ws.subscriptions = new Set();
    ws.isAlive = true;
    ws.on('pong', () => {
      ws.isAlive = true;
    });

    ws.on('message', (raw) => {
      try {
        const msg = JSON.parse(raw.toString());

        if (msg.type === 'hello' && typeof msg.userId === 'string') {
          ws.userId = msg.userId; // có thể dùng để cá nhân hoá sau này
        }

        if (
          msg.type === 'subscribe' &&
          typeof msg.conversationId === 'string'
        ) {
          ws.subscriptions.add(msg.conversationId);
          ws.send(
            JSON.stringify({
              type: 'subscribed',
              conversationId: msg.conversationId,
            })
          );
          console.log('[WS] +sub', msg.conversationId);
        }

        if (
          msg.type === 'unsubscribe' &&
          typeof msg.conversationId === 'string'
        ) {
          ws.subscriptions.delete(msg.conversationId);
          ws.send(
            JSON.stringify({
              type: 'unsubscribed',
              conversationId: msg.conversationId,
            })
          );
          console.log('[WS] -sub', msg.conversationId);
        }
      } catch (e) {
        console.error('[WS] bad message', e.message);
      }
    });
  });

  // ping/pong keepalive
  setInterval(() => {
    _wss?.clients.forEach((ws) => {
      if (!ws.isAlive) return ws.terminate();
      ws.isAlive = false;
      try {
        ws.ping();
      } catch {}
    });
  }, 30000);

  console.log('WebSocket server ready');
}

/**
 * Phát message tới 1 conversation.
 * Nếu payload là message và có senderId, sẽ enrich thêm senderProfile: {_id, name, email, avatar}
 */
export async function broadcastToConversation(conversationId, payloadObj) {
  if (!_wss) return;
  // console.log('conversationID: ', conversationId);
  // console.log('payloadObj: ', payloadObj);

  // Enrich nếu là event message
  let enriched = payloadObj;
  try {
    const isMessageEvent =
      payloadObj && payloadObj.type === 'message' && payloadObj.message;
    const senderId = isMessageEvent
      ? (payloadObj.message.senderId || payloadObj.message.sender)?.toString()
      : null;

    if (isMessageEvent && senderId) {
      // Lấy profile người gửi (chỉ field cần thiết)
      const u = await User.findById(senderId, '_id name email avatar').lean();
      const senderProfile = u
        ? {
            _id: u._id.toString(),
            name: u.name,
            email: u.email,
            avatar: u.avatar,
          }
        : null;

      // Chuẩn hoá message (tránh mutate tham chiếu ngoài)
      const msg = { ...payloadObj.message };
      if (msg.senderId && typeof msg.senderId !== 'string') {
        try {
          msg.senderId = msg.senderId.toString();
        } catch {}
      }
      enriched = {
        ...payloadObj,
        conversationId,
        message: { ...msg, senderProfile },
      };
    }
  } catch (e) {
    console.error('[WS] enrich error:', e);
    // vẫn phát payload gốc nếu enrich lỗi
  }

  const payload = JSON.stringify(enriched);
  let delivered = 0;
  console.log(_wss.clients);

  _wss.clients.forEach((ws) => {
    console.log('ws.readyState === ws.OPEN: ', ws.readyState === ws.OPEN);
    console.log(
      ' ws.subscriptions?.has(conversationId):',
      ws.subscriptions?.has(conversationId)
    );

    if (ws.readyState === ws.OPEN && ws.subscriptions?.has(conversationId)) {
      console.log('[WS] broadcast', conversationId, 'delivered=', delivered);
      ws.send(payload);
    }
  });
}
