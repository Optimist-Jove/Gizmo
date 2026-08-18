export declare enum MessageStatus {
    SENT = "SENT",
    DELIVERED = "DELIVERED",
    READ = "READ"
}
export declare enum SecurityLevel {
    STANDARD = "STANDARD",
    HIGH = "HIGH",
    MAXIMUM = "MAXIMUM",
    NONE = "NONE"
}
export declare class Message {
    id: string;
    senderId: string;
    receiverId: string;
    ciphertext: string;
    securityLevel: SecurityLevel;
    protocolVersion: string;
    ephemeralPublicKey: string;
    nonce: string;
    authTag: string;
    status: MessageStatus;
    createdAt: Date;
}
