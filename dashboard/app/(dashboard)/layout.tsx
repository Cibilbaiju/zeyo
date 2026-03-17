'use client';

import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { useAuthStore } from '@/store/authStore';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import {
    LayoutDashboard,
    Users,
    HardHat,
    Map as MapIcon,
    ShoppingBag,
    Wallet,
    BarChart3,
    LogOut,
    Menu,
    Settings,
    FileText,
    ChevronDown,
    ChevronRight,
    UserX,
    UserCheck,
    Clock
} from 'lucide-react';
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet';
import { ScrollArea } from "@/components/ui/scroll-area";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Collapsible, CollapsibleContent, CollapsibleTrigger } from "@/components/ui/collapsible";

const sidebarItems = [
    { icon: LayoutDashboard, label: 'Dashboard', href: '/' },
    { icon: ShoppingBag, label: 'Orders', href: '/orders' },
    { icon: MapIcon, label: 'Live Map', href: '/map' },
    { icon: Users, label: 'Users', href: '/users' },
    // "New Providers" moved to sub-item
    {
        icon: HardHat,
        label: 'Providers',
        href: '/providers',
        children: [
            { icon: UserX, label: 'Unverified', href: '/providers/unverified' },
            { icon: Clock, label: 'Waitlist', href: '/providers/waitlist' },
            { icon: UserCheck, label: 'Verified', href: '/providers/verified' },
        ]
    },
    { icon: Wallet, label: 'Finance', href: '/finance' },
    { icon: BarChart3, label: 'Analytics', href: '/analytics' },
    { icon: Settings, label: 'Settings', href: '/settings' },
];

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
    const router = useRouter();
    const pathname = usePathname();
    const { isAuthenticated, logout, user, _hasHydrated } = useAuthStore();
    const [isMobileOpen, setIsMobileOpen] = useState(false);

    // Auto-expand if child is active
    const isProviderActive = pathname?.startsWith('/providers');
    const [isProvidersOpen, setIsProvidersOpen] = useState(false);

    useEffect(() => {
        if (isProviderActive) setIsProvidersOpen(true);
    }, [isProviderActive]);

    useEffect(() => {
        // Only redirect if hydrated and not authenticated
        if (_hasHydrated && !isAuthenticated) {
            router.push('/login');
        }
    }, [isAuthenticated, _hasHydrated, router]);

    // Show nothing (or loader) until hydrated
    if (!_hasHydrated) return null;

    if (!isAuthenticated) return null;

    const SidebarContent = () => (
        <div className="flex flex-col h-full bg-slate-50 border-r border-slate-200 text-slate-900">
            <div className="p-6 border-b border-slate-200">
                {/* Logo */}
                <div className="flex items-center gap-2">
                    <img src="/zeyo_logo.png" alt="Zeyo" className="h-8 w-auto object-contain" />
                </div>
            </div>

            <ScrollArea className="flex-1 py-4">
                <nav className="space-y-1 px-3">
                    {sidebarItems.map((item) => {
                        const isActive = item.href === '/' ? pathname === '/' : pathname?.startsWith(item.href);

                        if (item.children) {
                            return (
                                <Collapsible
                                    key={item.label}
                                    open={isProvidersOpen}
                                    onOpenChange={setIsProvidersOpen}
                                    className="space-y-1"
                                >
                                    <CollapsibleTrigger asChild>
                                        <div className={`flex items-center justify-between px-4 py-3 text-sm font-medium rounded-lg transition-colors cursor-pointer
                                            ${isActive ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-200 hover:text-black'}`}
                                        >
                                            <div className="flex items-center">
                                                <item.icon className="mr-3 h-5 w-5 text-slate-500" />
                                                {item.label}
                                            </div>
                                            {isProvidersOpen ? <ChevronDown className="h-4 w-4" /> : <ChevronRight className="h-4 w-4" />}
                                        </div>
                                    </CollapsibleTrigger>
                                    <CollapsibleContent className="space-y-1 pl-4">
                                        {item.children.map((child) => {
                                            const isChildActive = pathname === child.href;
                                            return (
                                                <Link key={child.href} href={child.href} onClick={() => setIsMobileOpen(false)}>
                                                    <div className={`flex items-center px-4 py-2 text-sm font-medium rounded-lg transition-colors
                                                        ${isChildActive
                                                            ? 'bg-white shadow-sm text-black border border-slate-200'
                                                            : 'text-slate-500 hover:bg-slate-200 hover:text-slate-900'}`}
                                                    >
                                                        <child.icon className="mr-3 h-4 w-4 opacity-70" />
                                                        {child.label}
                                                    </div>
                                                </Link>
                                            );
                                        })}
                                    </CollapsibleContent>
                                </Collapsible>
                            );
                        }

                        return (
                            <Link key={item.href} href={item.href} onClick={() => setIsMobileOpen(false)}>
                                <div
                                    className={`flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-colors
                    ${isActive
                                            ? 'bg-white shadow-sm text-black border border-slate-200'
                                            : 'text-slate-600 hover:bg-slate-200 hover:text-black'
                                        }`}
                                >
                                    <item.icon className={`mr-3 h-5 w-5 ${isActive ? 'text-black' : 'text-slate-500'}`} />
                                    {item.label}
                                </div>
                            </Link>
                        );
                    })}
                </nav>
            </ScrollArea>

            <div className="p-4 border-t border-slate-200">
                <div className="flex items-center gap-3 mb-4">
                    <Avatar>
                        <AvatarImage src={`https://ui-avatars.com/api/?name=${user?.name}&background=random`} />
                        <AvatarFallback>{user?.name?.[0]}</AvatarFallback>
                    </Avatar>
                    <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium truncate text-slate-900">{user?.name}</p>
                        <p className="text-xs text-slate-500 truncate capitalize">{user?.role}</p>
                    </div>
                </div>
                <Button
                    variant="outline"
                    className="w-full border-slate-300 bg-white hover:bg-slate-100 text-slate-700"
                    onClick={() => {
                        logout();
                        router.push('/login');
                    }}
                >
                    <LogOut className="mr-2 h-4 w-4" />
                    Logout
                </Button>
            </div>
        </div>
    );

    return (
        <div className="flex h-screen bg-slate-50">
            {/* Desktop Sidebar */}
            <aside className="hidden md:flex w-64 flex-col fixed inset-y-0 z-50">
                <SidebarContent />
            </aside>

            {/* Main Content */}
            <main className="flex-1 md:pl-64 flex flex-col h-screen overflow-hidden">
                {/* Mobile Header */}
                <header className="md:hidden flex items-center justify-between p-4 bg-white border-b">
                    <span className="font-bold text-lg">Zeyo Admin</span>
                    <Sheet open={isMobileOpen} onOpenChange={setIsMobileOpen}>
                        <SheetTrigger asChild>
                            <Button variant="ghost" size="icon"><Menu /></Button>
                        </SheetTrigger>
                        <SheetContent side="left" className="p-0 border-r-slate-800 w-64">
                            <SidebarContent />
                        </SheetContent>
                    </Sheet>
                </header>

                {/* Page Content */}
                <ScrollArea className="flex-1 p-6">
                    {children}
                </ScrollArea>
            </main>
        </div>
    );
}
