'use client';

import { useSocket } from '@/hooks/useSocket';
import { useEffect, useState } from 'react';
import { Badge } from '@/components/ui/badge';
import { Activity } from 'lucide-react';

export function ServerStatus() {
    const { socket } = useSocket();
    const [isConnected, setIsConnected] = useState(false);

    useEffect(() => {
        if (!socket) return;

        function onConnect() {
            setIsConnected(true);
        }

        function onDisconnect() {
            setIsConnected(false);
        }

        if (socket.connected) {
            setIsConnected(true);
        }

        socket.on('connect', onConnect);
        socket.on('disconnect', onDisconnect);

        return () => {
            socket.off('connect', onConnect);
            socket.off('disconnect', onDisconnect);
        };
    }, [socket]);

    return (
        <div className="flex items-center space-x-2">
            <span className={`h-2.5 w-2.5 rounded-full ${isConnected ? 'bg-green-500' : 'bg-red-500'}`}></span>
            <span className={`text-sm font-medium ${isConnected ? 'text-green-600' : 'text-red-600'}`}>
                {isConnected ? 'Online' : 'Offline'}
            </span>
        </div>
    );
}
