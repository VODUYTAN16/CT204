import mongoose from 'mongoose';

const membershipSchema = new mongoose.Schema(
  {
    conversationId: {
      type: mongoose.Types.ObjectId,
      ref: 'Conversation',
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    role: {
      type: String,
      enum: ['owner', 'admin', 'member'],
      default: 'member',
    },
    status: {
      type: String,
      enum: ['active', 'left', 'removed'],
      default: 'active',
      index: true,
    },
    lastReadAt: { type: Date },
  },
  { timestamps: true }
);

membershipSchema.index({ conversationId: 1, userId: 1 }, { unique: true });

export const Membership = mongoose.model('Membership', membershipSchema);
