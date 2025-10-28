import mongoose from 'mongoose';

const messageSchema = new mongoose.Schema(
  {
    clientMessageId: { type: String },
    sender: { type: String, required: true },
    avatar: { type: String },
    name: { type: String },
    text: { type: String, required: true },
    encryptAes: [
      {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
        encryptedAesKey: { type: String },
      },
    ],
    captions: { type: String },
    timestamp: { type: Date, default: Date.now },
  },
  { _id: true }
);

const listChatSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },
    messages: [messageSchema],
  },
  { timestamps: true }
);

export const ListChat = mongoose.model('ListChat', listChatSchema);
