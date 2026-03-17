'use client';

import { useEffect } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import api from '@/lib/api';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Loader2, Users, Briefcase, Activity, DollarSign } from 'lucide-react';
import { useSocket } from '@/hooks/useSocket';

import { ServerStatus } from '@/components/server-status';

export default function DashboardPage() {
    const queryClient = useQueryClient();
    const { socket } = useSocket();

    useEffect(() => {
        if (!socket) return;

        socket.on('job:created', () => {
            // ... existing code ...
            // Also invalidate skill sessions if we add socket event for it later
            queryClient.invalidateQueries({ queryKey: ['skill-sessions'] });
        });

        socket.on('job:created', () => {
            queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
        });

        socket.on('job:updated', () => {
            queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
        });

        socket.on('technician:moved', () => {
            queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
        });

        return () => {
            socket.off('job:created');
            socket.off('job:updated');
            socket.off('technician:moved');
        };
    }, [socket, queryClient]);

    const { data: stats, isLoading } = useQuery({
        queryKey: ['dashboard-stats'],
        queryFn: async () => {
            const res = await api.get('/jobs/stats');
            return res.data;
        },
        refetchInterval: 5000,
    });

    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <h1 className="text-3xl font-bold tracking-tight">Dashboard Overview</h1>
                <div className="flex items-center space-x-4">
                    <ServerStatus />
                </div>
            </div>

            <div className="grid gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium">Total Revenue</CardTitle>
                        <DollarSign className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold">
                            {isLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : `₹${stats?.revenue || 0}`}
                        </div>
                        <p className="text-xs text-muted-foreground">Lifetime earnings</p>
                    </CardContent>
                </Card>
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium">Active Users</CardTitle>
                        <Users className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold flex items-center">
                            {isLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : (stats?.activeUsers || 0)}
                        </div>
                        <p className="text-xs text-muted-foreground">Registered users</p>
                    </CardContent>
                </Card>
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium">Active Jobs</CardTitle>
                        <Briefcase className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold flex items-center">
                            {isLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : (stats?.activeJobs || 0)}
                        </div>
                        <p className="text-xs text-muted-foreground">Pending or In-Progress</p>
                    </CardContent>
                </Card>
                <Card>
                    <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
                        <CardTitle className="text-sm font-medium">Total Providers</CardTitle>
                        <Activity className="h-4 w-4 text-muted-foreground" />
                    </CardHeader>
                    <CardContent>
                        <div className="text-2xl font-bold flex items-center">
                            {isLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : (stats?.activeProviders || 0)}
                        </div>
                        <p className="text-xs text-muted-foreground">Verified technicians</p>
                    </CardContent>
                </Card>
            </div>

            <div className="grid gap-4 grid-cols-1 lg:grid-cols-7">
                <Card className="col-span-4">
                    <CardHeader>
                        <CardTitle>Overview</CardTitle>
                    </CardHeader>
                    <CardContent className="pl-2">
                        <div className="h-[200px] flex items-center justify-center text-slate-400">
                            Analytics Coming Soon
                        </div>
                    </CardContent>
                </Card>
                <Card className="col-span-3">
                    <CardHeader>
                        <CardTitle>Recent Sales</CardTitle>
                        <p className="text-sm text-muted-foreground">
                            Latest completed jobs.
                        </p>
                    </CardHeader>
                    <CardContent>
                        <div className="space-y-8">
                            {isLoading ? (
                                <Loader2 className="mx-auto h-8 w-8 animate-spin text-slate-400" />
                            ) : stats?.recentSales?.length > 0 ? (
                                stats.recentSales.map((sale: any, i: number) => (
                                    <div key={i} className="flex items-center">
                                        <div className="space-y-1">
                                            <p className="text-sm font-medium leading-none">{sale.name}</p>
                                            <p className="text-sm text-muted-foreground">{sale.email}</p>
                                        </div>
                                        <div className="ml-auto font-medium">+₹{sale.amount}</div>
                                    </div>
                                ))
                            ) : (
                                <p className="text-sm text-slate-500 text-center">No completed jobs yet.</p>
                            )}
                        </div>
                    </CardContent>
                </Card>
            </div>
            {/* Skill Sessions Section */}
            <div className="grid gap-4 grid-cols-1">
                <Card>
                    <CardHeader>
                        <CardTitle>Upcoming Skill Sessions</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <SkillSessionsList />
                    </CardContent>
                </Card>
            </div>
        </div>
    );
}

import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Video, Check, X, ExternalLink } from 'lucide-react';

function SkillSessionsList() {
    const queryClient = useQueryClient();
    const { data: sessions, isLoading } = useQuery({
        queryKey: ['skill-sessions'],
        queryFn: async () => {
            const res = await api.get('/technician/skill-sessions');
            return res.data;
        },
        refetchInterval: 5000,
    });

    const handleApprove = async (id: any) => {
        try {
            await api.post(`/technician/skill-session/${id}/approve`);
            queryClient.invalidateQueries({ queryKey: ['skill-sessions'] });
            queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
        } catch (e) {
            console.error('Approve failed', e);
        }
    };

    const handleReject = async (id: any) => {
        try {
            await api.post(`/technician/skill-session/${id}/reject`);
            queryClient.invalidateQueries({ queryKey: ['skill-sessions'] });
            queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
        } catch (e) {
            console.error('Reject failed', e);
        }
    };

    if (isLoading) {
        return <Loader2 className="h-6 w-6 animate-spin text-slate-400" />;
    }

    if (!sessions || sessions.length === 0) {
        return <div className="text-sm text-slate-500">No upcoming sessions.</div>;
    }

    return (
        <div className="space-y-4">
            {sessions.filter((s: any) => s.status !== 'approved' && s.status !== 'rejected' && s.status !== 'waitlist').map((session: any) => (
                <div key={session.id} className="flex flex-col sm:flex-row sm:items-center justify-between border-b pb-4 last:border-0 last:pb-0 gap-4">
                    <div>
                        <div className="flex items-center gap-2">
                            <p className="font-medium">{session.technician_name || 'Unknown Technician'}</p>
                            <Badge variant={session.status === 'approved' ? 'default' : session.status === 'rejected' ? 'destructive' : 'outline'}>
                                {session.status}
                            </Badge>
                            {session.was_previously_rejected && (
                                <Badge variant="destructive" className="ml-2 text-xs">
                                    Once Rejected
                                </Badge>
                            )}
                        </div>
                        <div className="flex items-center space-x-2 mt-1">
                            <p className="text-sm text-muted-foreground">{session.technician_phone}</p>
                            {session.service_names && (
                                <span className="text-xs bg-slate-100 px-2 py-0.5 rounded text-slate-600">
                                    {session.service_names}
                                </span>
                            )}
                        </div>
                        <div className="text-xs text-muted-foreground mt-1">
                            {new Date(session.scheduled_at).toLocaleString()}
                        </div>
                    </div>

                    <div className="flex items-center gap-2">
                        {/* Action Buttons */}
                        <div className="flex items-center gap-2">
                            {/* Video Call Button */}
                            {session.meeting_link ? (
                                (session.status === 'scheduled' || session.status === 'rescheduled' || session.status === 'ongoing') ? (
                                    <Button
                                        size="sm"
                                        onClick={async () => {
                                            try {
                                                // Only start if not already ongoing
                                                if (session.status !== 'ongoing') {
                                                    await api.post(`/technician/skill-session/${session.id}/start`);
                                                    queryClient.invalidateQueries({ queryKey: ['skill-sessions'] });
                                                }
                                                // Generate Jitsi link with config to start with video/audio enabled
                                                // Note: 'Host' logic in Jitsi usually requires JWT, but we can ensure the admin joins.
                                                window.open(session.meeting_link, '_blank');
                                            } catch (e) {
                                                console.error('Failed to start session', e);
                                            }
                                        }}
                                        className="bg-blue-600 hover:bg-blue-700"
                                    >
                                        <Video className="w-4 h-4 mr-2" />
                                        {session.status === 'ongoing' ? 'Re-Join' : 'Join'}
                                    </Button>
                                ) : null
                            ) : null}

                            {/* Decision Buttons */}
                            {(session.status === 'scheduled' || session.status === 'rescheduled' || session.status === 'ongoing' || session.status === 'pending') && (
                                <>
                                    <Button
                                        size="sm"
                                        onClick={() => handleApprove(session.id)}
                                        className="bg-green-600 hover:bg-green-700"
                                        // Accept is allowed if ongoing OR if the user just wants to bypass
                                        disabled={session.status !== 'ongoing'}
                                    >
                                        <Check className="w-4 h-4 mr-2" />
                                        Accept
                                    </Button>
                                    <Button
                                        size="sm"
                                        onClick={async () => {
                                            try {
                                                await api.post(`/technician/skill-session/${session.id}/waitlist`);
                                                queryClient.invalidateQueries({ queryKey: ['skill-sessions'] });
                                                queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
                                            } catch (e) {
                                                console.error('Waitlist failed', e);
                                            }
                                        }}
                                        variant="secondary"
                                    >
                                        Wait
                                    </Button>
                                </>
                            )}
                        </div>
                    </div>
                </div>
            ))}
        </div>
    );
}
