# 🚀 Zeyo — Smart On-Demand Home Service Platform

> ⚡ A next-generation full-stack platform for seamless home services, real-time tracking, and scalable operations.

---

## ⚠️ Development Status

> 🚧 **Currently in Active Development**  
Zeyo is evolving rapidly. Features, APIs, and architecture may change as we move toward production readiness.

---

## 🌟 Overview

Zeyo is a **production-grade, scalable on-demand home service ecosystem** designed to connect customers with service providers in real-time.

It combines:

- ⚡ High-performance backend  
- 📊 Intelligent admin dashboard  
- 📱 Dual Flutter mobile applications  
- 🔄 Real-time communication & tracking  

---

## 🏗 Monorepo Architecture

```
zeyo/
│
├── backend/            # Core backend APIs, auth, sockets, queues
├── dashboard/          # Admin control panel (Next.js)
├── zeyo_app/           # Customer mobile application
├── zeyosrv_app/        # Service provider mobile app
│
├── .github/workflows/  # CI/CD automation
├── .vscode/            # Dev configs
├── LICENSE
└── README.md
```

---

## 🧠 System Architecture (High-Level)

```
            ┌────────────────────┐
            │   Mobile Apps      │
            │ (User & Provider)  │
            └────────┬───────────┘
                     │
                     ▼
            ┌────────────────────┐
            │   API Gateway      │
            │ (Node + Express)   │
            └────────┬───────────┘
                     │
     ┌───────────────┼───────────────┐
     ▼               ▼               ▼
 PostgreSQL       Redis          Kafka
(Database)       (Cache)     (Event Stream)
                     │
                     ▼
            ┌────────────────────┐
            │   Admin Dashboard  │
            └────────────────────┘
```

---

## 🚀 Tech Stack

### 🔧 Backend
- Node.js + Express  
- PostgreSQL + Prisma  
- Socket.io  
- Apache Kafka  
- Redis  
- JWT Authentication  
- Bcrypt  
- Twilio API  
- Google Maps API  

---

### 🖥 Admin Dashboard
- Next.js 15 (App Router)  
- Tailwind CSS + Shadcn/ui  
- Zustand + React Query  
- Recharts  
- Lucide React  

---

### 📱 Mobile Applications
- Flutter (Dart)  
- Provider  
- Go Router  
- Google Maps SDK  
- Lottie Animations  
- Flutter Animate  

---

## ✨ Core Features

### 🔐 Authentication & Security
- OTP-based login via Twilio  
- JWT session handling  
- Secure password hashing  

---

### 📍 Real-Time Tracking
- Live provider tracking  
- Route visualization  
- Real-time updates using Socket.io  

---

### 🛠 Service Booking System
- Category-based services  
- Dynamic job allocation  
- Smart provider matching  

---

### 🧑‍💼 Admin Dashboard
- Manage users & providers  
- Monitor bookings  
- Analytics & insights  
- System controls  

---

### 🔄 Real-Time Architecture
- Kafka-based event streaming  
- Instant notifications  
- Scalable system design  

---

### 🎨 UI/UX Experience
- Smooth animations (Lottie)  
- Micro-interactions  
- Clean and modern UI  

---

## 🔁 Booking Flow

```
1. User selects service
2. Request sent to backend
3. Nearby providers notified
4. Provider accepts job
5. Live tracking starts
6. Service completed
7. Payment & feedback
```

---

## 🛠 Getting Started

### 📋 Prerequisites

- Flutter SDK (≥ 3.5.0)  
- Node.js (≥ 18)  
- Docker (PostgreSQL, Redis, Kafka)  

---

### ⚙️ Installation

#### 1️⃣ Clone Repository
```
git clone https://github.com/Cibilbaiju/zeyo.git
cd zeyo
```

---

#### 2️⃣ Backend Setup
```
cd backend
npm install
cp .env.example .env
npm run dev
```

---

#### 3️⃣ Dashboard Setup
```
cd dashboard
npm install
npm run dev
```

---

#### 4️⃣ Mobile Apps

**User App**
```
cd zeyo_app
flutter pub get
flutter run
```

**Provider App**
```
cd zeyosrv_app
flutter pub get
flutter run
```

---

## 🔐 Environment Variables

```
DATABASE_URL=
JWT_SECRET=
REDIS_URL=
KAFKA_BROKER=

TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=

GOOGLE_MAPS_API_KEY=
```

---

## 🔒 Security Practices

- Secrets stored in environment variables  
- Sensitive files ignored via `.gitignore`  
- Secure API authentication  
- Protection against SQL injection & XSS  

---

## 📈 Scalability & Performance

- Redis caching  
- Kafka event streaming  
- Modular architecture  
- Optimized database queries  

---

## 🚀 Future Roadmap

- Payment Integration (UPI, Stripe)  
- AI-based recommendations  
- Advanced analytics  
- Multi-language support  
- Voice-based booking  
- Subscription system  

---

## 🤝 Contributing

```
# Fork the repo
# Create a new branch
git checkout -b feature/your-feature

# Commit changes
git commit -m "Add new feature"

# Push changes
git push origin feature/your-feature
```

---

## 📜 License

Apache 2.0 License

---

## 👨‍💻 Author

Cibil Baiju  
Full Stack Developer | Mobile App Developer | AI Enthusiast  

---

## ⭐ Support

If you like this project:

- Star the repository  
- Fork it  
- Contribute  

---

## 💡 Vision

Zeyo aims to become a complete ecosystem for on-demand services focused on:

- Speed  
- Reliability  
- Scalability  
- Premium user experience  

---
