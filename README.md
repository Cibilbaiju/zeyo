# Zeyo - Smart On-Demand Home Service Platform

> [!IMPORTANT]
> **🚧 Development Status:** This project is currently in the **Developing Stage**. Features and APIs are subject to change as we work towards a stable release.

Zeyo is a comprehensive monorepo containing a full-stack on-demand home service platform. It integrates a scalable backend, a high-performance admin dashboard, and dual-sided mobile applications for both consumers and service providers.

## 🏗 Project Architecture

The project is organized as a monorepo to ensure seamless integration between services:

*   **[`backend/`](./backend)**: High-performance API server built with Node.js and Express. Handles real-time communication via Socket.io and utilizes Redis/Kafka for scalability.
*   **[`dashboard/`](./dashboard)**: A modern, responsive admin oversight panel built with Next.js 15 and Tailwind CSS.
*   **[`zeyo_app/`](./zeyo_app)**: The consumer-facing Flutter application for booking and tracking services.
*   **[`zeyosrv_app/`](./zeyosrv_app)**: The service provider-facing Flutter application for managing jobs and earnings.

## 🚀 Technical Stack

### Backend
- **Framework**: Node.js, Express
- **Database**: PostgreSQL (Prisma/PG)
- **Real-time**: Socket.io
- **Queue/Streaming**: Apache Kafka
- **Caching**: Redis
- **Security**: JWT Authentication, Bcrypt hashing
- **Integration**: Twilio (OTP Verification), Google Maps API

### Admin Dashboard
- **Framework**: Next.js 15 (App Router)
- **Styling**: Tailwind CSS, Shadcn/ui
- **State Management**: Zustand, React Query
- **Charts**: Recharts
- **Icons**: Lucide React

### Mobile Applications (Consumer & Provider)
- **Framework**: Flutter (Dart)
- **Navigation**: Go Router
- **State Management**: Provider
- **Mapping**: Google Maps SDK
- **Animations**: Lottie, Flutter Animate

## ✨ Key Features

- **OTP Authentication**: Secure login via Twilio SMS verification.
- **Geospatial Tracking**: Real-time tracking of service providers using Google Maps.
- **Service Management**: Dynamic booking system with categorized services.
- **Admin Oversight**: Comprehensive dashboard for managing users, service providers, and bookings.
- **Micro-interactions**: Fluid UI with high-quality animations across web and mobile.

## 🛠 Getting Started

### Prerequisites
- Flutter SDK (v3.5.0+)
- Node.js (v18+)
- PostgreSQL, Redis, and Kafka (via Docker)

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/Cibilbaiju/zeyo.git
    cd zeyo
    ```

2.  **Backend Setup**:
    ```bash
    cd backend
    npm install
    # Create .env based on .env.example
    npm run dev
    ```

3.  **Dashboard Setup**:
    ```bash
    cd dashboard
    npm install
    npm run dev
    ```

4.  **Mobile App Setup**:
    ```bash
    cd zeyo_app # or zeyosrv_app
    flutter pub get
    flutter run
    ```

## 🔒 Security Notice

This repository has been hardened to prevent accidental exposure of sensitive information. All API keys (Google Maps, Twilio, etc.) are managed via environment variables and platform-specific secret files (like `local.properties` and `Secrets.plist`) which are strictly ignored by version control.

---
© 2024 Zeyo Team. All rights reserved.
