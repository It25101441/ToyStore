package com.toystore.model;

import java.util.Date;
import java.util.List;

public class Message {
    private int messageId;
    private int senderId;
    private int receiverId;
    private String subject;
    private String message;
    private Integer replyToId;
    private boolean isRead;
    private Date createdAt;

    // Additional fields for display
    private String senderName;
    private String receiverName;
    private List<Message> replies;

    public Message() {}

    public Message(int senderId, int receiverId, String subject, String message) {
        this.senderId = senderId;
        this.receiverId = receiverId;
        this.subject = subject;
        this.message = message;
        this.isRead = false;
    }

    public Message(int senderId, int receiverId, String subject, String message, Integer replyToId) {
        this(senderId, receiverId, subject, message);
        this.replyToId = replyToId;
    }

    // Getters and Setters
    public int getMessageId() { return messageId; }
    public void setMessageId(int messageId) { this.messageId = messageId; }

    public int getSenderId() { return senderId; }
    public void setSenderId(int senderId) { this.senderId = senderId; }

    public int getReceiverId() { return receiverId; }
    public void setReceiverId(int receiverId) { this.receiverId = receiverId; }

    public String getSubject() { return subject; }
    public void setSubject(String subject) { this.subject = subject; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public Integer getReplyToId() { return replyToId; }
    public void setReplyToId(Integer replyToId) { this.replyToId = replyToId; }

    public boolean isRead() { return isRead; }
    public void setRead(boolean read) { isRead = read; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public String getSenderName() { return senderName; }
    public void setSenderName(String senderName) { this.senderName = senderName; }

    public String getReceiverName() { return receiverName; }
    public void setReceiverName(String receiverName) { this.receiverName = receiverName; }

    public List<Message> getReplies() { return replies; }
    public void setReplies(List<Message> replies) { this.replies = replies; }
}
