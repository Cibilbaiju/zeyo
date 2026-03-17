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
import { format } from 'date-fns';
import { Loader2 } from 'lucide-react';

interface Job {
    id: string;
    user_name: string;
    service_name: string;
    status: string;
    created_at: string;
    pickup_lat: number;
    pickup_lng: number;
    order_id?: string;
}

export default function OrdersPage() {
    const { data: jobs, isLoading, error } = useQuery<Job[]>({
        queryKey: ['jobs'],
        queryFn: async () => {
            const res = await api.get('/jobs');
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
                Error loading orders. Please try again later.
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight">Order Management</h1>
                <Badge variant="outline" className="text-sm">
                    Total: {jobs?.length || 0}
                </Badge>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle>Recent Orders</CardTitle>
                </CardHeader>
                <CardContent>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>Order ID</TableHead>
                                <TableHead>Customer</TableHead>
                                <TableHead>Service</TableHead>
                                <TableHead>Status</TableHead>
                                <TableHead>Date</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {jobs?.map((job) => (
                                <TableRow key={job.id}>
                                    <TableCell className="font-mono text-xs font-semibold">
                                        {job.order_id || job.id.slice(0, 8) + '...'}
                                    </TableCell>
                                    <TableCell>
                                        {job.user_name || 'Unknown'}
                                    </TableCell>
                                    <TableCell>
                                        {job.service_name || 'Service'}
                                    </TableCell>
                                    <TableCell>
                                        <Badge variant={job.status === 'completed' ? 'default' : 'secondary'} className={job.status === 'completed' ? 'bg-green-600' : ''}>
                                            {job.status}
                                        </Badge>
                                    </TableCell>
                                    <TableCell className="text-slate-500">
                                        {job.created_at ? format(new Date(job.created_at), 'PPP') : '-'}
                                    </TableCell>
                                </TableRow>
                            ))}
                            {jobs?.length === 0 && (
                                <TableRow>
                                    <TableCell colSpan={5} className="text-center py-8 text-slate-500">
                                        No orders found.
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
