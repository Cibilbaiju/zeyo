'use client';

import { useQuery } from '@tanstack/react-query';
import api from '@/lib/api';
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from '@/components/ui/table';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { format } from 'date-fns';
import { Loader2, CheckCircle2, XCircle } from 'lucide-react';

interface Technician {
    id: string;
    name: string;
    phone: string;
    is_verified: boolean;
    is_online: boolean;
    rating: number;
    wallet_balance: number;
    service_count: number;
    created_at: string;
}

export default function ProvidersPage() {
    const { data: providers, isLoading, error } = useQuery<Technician[]>({
        queryKey: ['providers'],
        queryFn: async () => {
            const res = await api.get('/technician');
            return res.data;
        },
    });

    if (isLoading) {
        return (
            <div className="flex h-[50vh] items-center justify-center">
                <Loader2 className="h-8 w-8 animate-spin text-slate-400" />
            </div>
        );
    }

    if (error) {
        return (
            <div className="p-4 text-red-500">
                Error loading providers. Please try again later.
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight">Provider Management</h1>
                <Badge variant="outline" className="text-sm">
                    Total: {providers?.length || 0}
                </Badge>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Service Providers</CardTitle>
                </CardHeader>
                <CardContent>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead className="w-[50px]"></TableHead>
                                <TableHead>Name</TableHead>
                                <TableHead>Status</TableHead>
                                <TableHead>Verification</TableHead>
                                <TableHead>Rating</TableHead>
                                <TableHead>Wallet</TableHead>
                                <TableHead>Services</TableHead>
                                <TableHead>Joined</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {providers?.map((tech) => (
                                <TableRow key={tech.id}>
                                    <TableCell>
                                        <Avatar className="h-8 w-8">
                                            <AvatarFallback>{tech.name ? tech.name[0] : 'T'}</AvatarFallback>
                                        </Avatar>
                                    </TableCell>
                                    <TableCell className="font-medium">
                                        <div className="flex flex-col">
                                            <span>{tech.name || 'N/A'}</span>
                                            <span className="text-xs text-slate-500">{tech.phone}</span>
                                        </div>
                                    </TableCell>
                                    <TableCell>
                                        <Badge variant={tech.is_online ? 'default' : 'secondary'} className={tech.is_online ? 'bg-green-600' : ''}>
                                            {tech.is_online ? 'Online' : 'Offline'}
                                        </Badge>
                                    </TableCell>
                                    <TableCell>
                                        {tech.is_verified ? (
                                            <div className="flex items-center text-green-600 text-sm font-medium">
                                                <CheckCircle2 className="w-4 h-4 mr-1" /> Verified
                                            </div>
                                        ) : (
                                            <div className="flex items-center text-amber-600 text-sm font-medium">
                                                <XCircle className="w-4 h-4 mr-1" /> Pending
                                            </div>
                                        )}
                                    </TableCell>
                                    <TableCell>
                                        <div className="flex items-center">
                                            <span className="font-bold mr-1">★</span> {tech.rating}
                                        </div>
                                    </TableCell>
                                    <TableCell>
                                        ₹{tech.wallet_balance}
                                    </TableCell>
                                    <TableCell>
                                        <Badge variant="outline">{tech.service_count}</Badge>
                                    </TableCell>
                                    <TableCell className="text-slate-500">
                                        {tech.created_at ? format(new Date(tech.created_at), 'PPP') : '-'}
                                    </TableCell>
                                </TableRow>
                            ))}
                            {providers?.length === 0 && (
                                <TableRow>
                                    <TableCell colSpan={8} className="text-center py-8 text-slate-500">
                                        No providers found.
                                    </TableCell>
                                </TableRow>
                            )}
                        </TableBody>
                    </Table>
                </CardContent>
            </Card>
        </div>
    );
}
