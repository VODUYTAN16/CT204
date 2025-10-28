import mongoose from 'mongoose';

const inviteSchema = new mongoose.Schema(
  {
    conversationId: {
      type: mongoose.Types.ObjectId,
      ref: 'Conversation',
      required: true,
    },
    inviterId: { type: mongoose.Types.ObjectId, ref: 'User', required: true },
    inviteeEmail: {
      type: String,
      required: true,
      lowercase: true,
      index: true,
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'expired', 'canceled'],
      default: 'pending',
      index: true,
    },
    expiresAt: { type: Date },
  },
  { timestamps: true }
);

export const Invite = mongoose.model('Invite', inviteSchema);
