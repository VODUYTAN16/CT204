import mongoose from 'mongoose';

const conversationSchema = new mongoose.Schema(
  {
    type: { type: String, enum: ['direct', 'group'], required: true },
    title: { type: String }, // với group
    createdBy: { type: mongoose.Types.ObjectId, ref: 'User' },
    directPair: {
      // với direct
      a: { type: mongoose.Types.ObjectId, ref: 'User' },
      b: { type: mongoose.Types.ObjectId, ref: 'User' },
    },
    lastMessageId: { type: mongoose.Types.ObjectId, ref: 'Message' },
    lastMessageAt: { type: Date },
  },
  { timestamps: true }
);

conversationSchema.index(
  { type: 1, 'directPair.a': 1, 'directPair.b': 1 },
  { unique: true, partialFilterExpression: { type: 'direct' } }
);
conversationSchema.index({ lastMessageAt: -1 });

export const Conversation = mongoose.model('Conversation', conversationSchema);
