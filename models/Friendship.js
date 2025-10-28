import mongoose from 'mongoose';

const friendshipSchema = new mongoose.Schema(
  {
    requesterId: { type: mongoose.Types.ObjectId, ref: 'User', required: true },
    addresseeId: { type: mongoose.Types.ObjectId, ref: 'User', required: true },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'blocked'],
      default: 'pending',
      index: true,
    },
  },
  { timestamps: true }
);

friendshipSchema.index({ requesterId: 1, addresseeId: 1 }, { unique: true });

export const Friendship = mongoose.model('Friendship', friendshipSchema);
