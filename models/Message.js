import mongoose from 'mongoose';

const messageSchema = new mongoose.Schema(
  {
    conversationId: {
      type: mongoose.Types.ObjectId,
      ref: 'Conversation',
      required: true,
      index: true,
    },
    senderId: { type: mongoose.Types.ObjectId, ref: 'User', required: true },
    clientMessageId: { type: String }, // để reconcile UI
    kind: {
      type: String,
      enum: ['text', 'image', 'file', 'system'],
      default: 'text',
    },
    text: { type: String }, // ciphertext AES
    media: { url: String, mime: String, size: Number },
    captions: { type: String },
    timestamp: { type: Date, default: Date.now, index: true },
    editedAt: { type: Date },
    deletedAt: { type: Date },
  },
  { timestamps: true }
);

export const Message = mongoose.model('Message', messageSchema);
