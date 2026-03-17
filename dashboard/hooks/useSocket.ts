import { useEffect, useState } from 'react';
import { Socket } from 'socket.io-client';
import { getSocket } from '@/lib/socket';
import { useAuthStore } from '@/store/authStore';

export const useSocket = () => {
    const [socket, setSocket] = useState<Socket | null>(null);
    const [isConnected, setIsConnected] = useState(false);
    const { token, user } = useAuthStore();

    useEffect(() => {
        if (!token) return;

        const socketInstance = getSocket(token || undefined);

        if (!socketInstance.connected) {
            socketInstance.auth = { token };
            socketInstance.connect(); // User Role? Dashboard usually has admin privileges
        }

        function onConnect() {
            setIsConnected(true);
            console.log('Socket connected');
            // Join admin room if needed
            socketInstance.emit('join', { room: 'admin' });
        }

        function onDisconnect() {
            setIsConnected(false);
            console.log('Socket disconnected');
        }

        function onConnectError(err: any) {
            console.error('Socket Connection Error:', err.message);
            setIsConnected(false);
        }

        socketInstance.on('connect', onConnect);
        socketInstance.on('disconnect', onDisconnect);
        socketInstance.on('connect_error', onConnectError);

        setSocket(socketInstance);

        return () => {
            socketInstance.off('connect', onConnect);
            socketInstance.off('disconnect', onDisconnect);
            socketInstance.off('connect_error', onConnectError);
            // Don't disconnect on unmount to keep connection alive across pages?  
            // Better to keep it alive for dashboard.
        };
    }, [token]);

    return { socket, isConnected };
};
