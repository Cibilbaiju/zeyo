'use client';

import { useEffect, useState } from 'react';
import { APIProvider, Map, AdvancedMarker, Pin } from '@vis.gl/react-google-maps';
import { useSocket } from '@/hooks/useSocket';
import { Card } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import api from '@/lib/api';

const GOOGLE_MAPS_API_KEY = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY || '';

interface TechLocation {
    id: string;
    lat: number;
    lng: number;
    status: string;
    name?: string;
}

export default function LiveMapPage() {
    const { socket } = useSocket();
    const [technicians, setTechnicians] = useState<Record<string, TechLocation>>({});
    const [center, setCenter] = useState({ lat: 12.9716, lng: 77.5946 });

    useEffect(() => {
        const fetchInitial = async () => {
            try {
                const res = await api.get('/technician?limit=100');
                const data = res.data;
                const initial: Record<string, TechLocation> = {};
                data.forEach((t: any) => {
                    if (t.current_lat && t.current_lng) {
                        initial[t.id] = {
                            id: t.id,
                            lat: parseFloat(t.current_lat),
                            lng: parseFloat(t.current_lng),
                            status: t.is_online ? 'online' : 'offline',
                            name: t.name
                        };
                    }
                });
                setTechnicians(initial);
            } catch (e) {
                console.error(e);
            }
        };
        fetchInitial();
    }, []);

    useEffect(() => {
        if (!socket) return;

        const handleMove = (data: TechLocation) => {
            setTechnicians(prev => ({
                ...prev,
                [data.id]: {
                    ...prev[data.id],
                    ...data,
                    lat: parseFloat(data.lat as any),
                    lng: parseFloat(data.lng as any)
                }
            }));
        };

        socket.on('technician:moved', handleMove);

        return () => {
            socket.off('technician:moved', handleMove);
        };
    }, [socket]);

    return (
        <div className="h-[calc(100vh-theme(spacing.24))] w-full rounded-lg overflow-hidden border relative">
            {!GOOGLE_MAPS_API_KEY && (
                <div className="absolute z-10 top-0 left-0 w-full bg-red-100 p-2 text-center text-xs text-red-800">
                    Error: Missing NEXT_PUBLIC_GOOGLE_MAPS_API_KEY in .env.local
                </div>
            )}

            <APIProvider apiKey={GOOGLE_MAPS_API_KEY}>
                <Map
                    defaultCenter={center}
                    defaultZoom={12}
                    mapId="DEMO_MAP_ID"
                    style={{ width: '100%', height: '100%' }}
                    gestureHandling={'greedy'}
                    disableDefaultUI={false}
                >
                    {Object.values(technicians).map((tech) => (
                        <AdvancedMarker
                            key={tech.id}
                            position={{ lat: tech.lat, lng: tech.lng }}
                            title={tech.name || tech.id}
                        >
                            <div className="relative group cursor-pointer">
                                <div className={`p-1 rounded-full border-2 transition-transform hover:scale-110 ${tech.status === 'online' ? 'border-green-500 bg-green-50' : 'border-slate-400 bg-slate-50'}`}>
                                    <Avatar className="h-8 w-8">
                                        <AvatarFallback className="text-[10px] bg-transparent">
                                            {tech.name?.[0] || 'T'}
                                        </AvatarFallback>
                                    </Avatar>
                                </div>
                                {/* Tooltip */}
                                <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 hidden group-hover:block whitespace-nowrap bg-black/80 backdrop-blur text-white text-xs px-2 py-1 rounded shadow-lg pointer-events-none">
                                    {tech.name || tech.id}
                                    <div className="text-[10px] opacity-75 capitalize">{tech.status}</div>
                                </div>
                            </div>
                        </AdvancedMarker>
                    ))}
                </Map>
            </APIProvider>

            <div className="absolute bottom-4 left-4 z-10 w-64">
                <Card className="bg-white/90 backdrop-blur shadow-lg border-none">
                    <div className="p-3 text-xs space-y-2">
                        <div className="flex items-center justify-between">
                            <span className="font-medium text-slate-700">Online Providers</span>
                            <Badge variant="default" className="bg-green-600 hover:bg-green-700">
                                {Object.values(technicians).filter(t => t.status === 'online').length}
                            </Badge>
                        </div>
                        <div className="flex items-center justify-between">
                            <span className="font-medium text-slate-700">Total Visible</span>
                            <Badge variant="secondary" className="bg-slate-200 text-slate-700">
                                {Object.values(technicians).length}
                            </Badge>
                        </div>
                    </div>
                </Card>
            </div>
        </div>
    );
}
