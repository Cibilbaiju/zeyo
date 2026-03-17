import { io, Socket } from 'socket.io-client';

const SOCKET_URL = process.env.NEXT_PUBLIC_API_URL?.replace('/api', '') || 'http://localhost:5001';

let socket: Socket;

export const getSocket = (token?: string) => {
    if (!socket) {
        // Try to get token from storage if not provided
        const authToken = token || (typeof window !== 'undefined' ? localStorage.getItem('token') : null);

        socket = io(SOCKET_URL, {
            autoConnect: false,
            // Allow polling fallback for better compatibility
            transports: ['polling', 'websocket'],
            auth: {
                token: authToken
            }
        });
        console.log('Socket initialized', SOCKET_URL);
    }
    return socket;
};
