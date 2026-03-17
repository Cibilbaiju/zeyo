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
import { Loader2 } from 'lucide-react';

interface User {
    id: string;
    name: string;
    email: string | null;
    phone: string;
    role: string;
    created_at: string;
}

import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';

export default function UsersPage() {
    const { data: users, isLoading: usersLoading } = useQuery<User[]>({
        queryKey: ['users'],
        queryFn: async () => {
            const res = await api.get('/users');
            return res.data;
        },
    });

    const { data: technicians, isLoading: techLoading } = useQuery<any[]>({
        queryKey: ['technicians'],
        queryFn: async () => {
            const res = await api.get('/technician');
            return res.data;
        },
    });

    const isLoading = usersLoading || techLoading;

    // Filter users
    const zeyoUsers = users?.filter(u => u.role === 'user') || [];
    const dashboardUsers = users?.filter(u => ['admin', 'super_admin'].includes(u.role)) || [];
    const zeyoSrvUsers = technicians || [];

    if (isLoading) {
        return (
            <div className="flex h-[50vh] items-center justify-center">
                <Loader2 className="h-8 w-8 animate-spin text-slate-400" />
            </div>
        );
    }

    const UserTable = ({ data, type }: { data: any[], type: 'user' | 'tech' }) => (
        <Card>
            <CardHeader>
                <CardTitle>{type === 'user' ? 'Users' : 'Providers'} List</CardTitle>
            </CardHeader>
            <CardContent>
                <Table>
                    <TableHeader>
                        <TableRow>
                            <TableHead className="w-[50px]"></TableHead>
                            <TableHead>Name</TableHead>
                            <TableHead>Contact</TableHead>
                            <TableHead>Role</TableHead>
                            <TableHead>Joined</TableHead>
                        </TableRow>
                    </TableHeader>
                    <TableBody>
                        {data.map((user) => (
                            <TableRow key={user.id}>
                                <TableCell>
                                    <Avatar className="h-8 w-8">
                                        <AvatarFallback>{user.name ? user.name[0] : 'U'}</AvatarFallback>
                                    </Avatar>
                                </TableCell>
                                <TableCell className="font-medium">
                                    {user.name || 'N/A'}
                                </TableCell>
                                <TableCell>
                                    <div className="flex flex-col">
                                        <span className="text-sm">{user.phone}</span>
                                        <span className="text-xs text-slate-500">{user.email}</span>
                                    </div>
                                </TableCell>
                                <TableCell>
                                    <Badge variant="secondary" className="capitalize">
                                        {user.role || (type === 'tech' ? 'Technician' : 'User')}
                                    </Badge>
                                </TableCell>
                                <TableCell className="text-slate-500">
                                    {user.created_at ? format(new Date(user.created_at), 'PPP') : '-'}
                                </TableCell>
                            </TableRow>
                        ))}
                        {data.length === 0 && (
                            <TableRow>
                                <TableCell colSpan={5} className="text-center py-8 text-slate-500">
                                    No records found.
                                </TableCell>
                            </TableRow>
                        )}
                    </TableBody>
                </Table>
            </CardContent>
        </Card>
    );

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight">User Management</h1>
            </div>

            <Tabs defaultValue="zeyo" className="space-y-4">
                <TabsList>
                    <TabsTrigger value="zeyo">Zeyo (Users)</TabsTrigger>
                    <TabsTrigger value="zeyosrv">ZeyoSrv (Providers)</TabsTrigger>
                    <TabsTrigger value="dashboard">Dashboard (Admins)</TabsTrigger>
                </TabsList>

                <TabsContent value="zeyo" className="space-y-4">
                    <UserTable data={zeyoUsers} type="user" />
                </TabsContent>

                <TabsContent value="zeyosrv" className="space-y-4">
                    <UserTable data={zeyoSrvUsers} type="tech" />
                </TabsContent>

                <TabsContent value="dashboard" className="space-y-4">
                    <UserTable data={dashboardUsers} type="user" />
                </TabsContent>
            </Tabs>
        </div>
    );
}
