import mongoose from 'mongoose';

const messageKeySchema = new mongoose.Schema(
  {
    messageId: {
      type: mongoose.Types.ObjectId,
      ref: 'Message',
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    encryptedAesKey: { type: String, required: true },
  },
  { timestamps: true }
);

messageKeySchema.index({ messageId: 1, userId: 1 }, { unique: true });

export const MessageKey = mongoose.model('MessageKey', messageKeySchema);
