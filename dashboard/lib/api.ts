import axios from 'axios';
import { useAuthStore } from '@/store/authStore';

const api = axios.create({
    baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5001/api',
    headers: {
        'Content-Type': 'application/json',
    },
    timeout: 15000, // 15 second timeout
});

api.interceptors.request.use((config) => {
    const token = useAuthStore.getState().token;
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

api.interceptors.response.use(
    (response) => {
        // Check if the response is actually JSON
        const contentType = response.headers['content-type'];
        if (contentType && !contentType.includes('application/json')) {
            console.warn('Received non-JSON response:', contentType);
        }
        return response;
    },
    (error) => {
        // Handle specific error cases
        if (error.response?.status === 401) {
            useAuthStore.getState().logout();
        }

        // Handle cases where server returns HTML instead of JSON
        if (error.response?.data && typeof error.response.data === 'string' && error.response.data.includes('<!DOCTYPE')) {
            console.error('Received HTML response instead of JSON. URL:', error.config?.url);
            error.message = 'Server returned an unexpected response';
        }

        return Promise.reject(error);
    }
);

export default api;

