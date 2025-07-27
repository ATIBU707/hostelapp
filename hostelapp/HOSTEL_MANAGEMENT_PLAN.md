# Hostel Management App - Development Plan

## 📋 Project Overview
A comprehensive hostel management system built with Flutter and Supabase to streamline hostel operations, resident management, and administrative tasks.

## 🎯 Core Features & Modules

### 1. User Management
- **Admin Dashboard**: Hostel managers/owners with full system access
- **Staff Portal**: Receptionists and maintenance staff with limited access
- **Student/Resident Portal**: Current residents with personal data access
- **Guest Portal**: Visitors and prospective residents

### 2. Room Management
- Room allocation and availability tracking
- Room types (single, double, dormitory)
- Room maintenance status tracking
- Bed assignment within rooms
- Floor and building organization

### 3. Booking & Reservation System
- Online booking for new residents
- Automated room assignment based on preferences
- Waitlist management for full capacity
- Check-in/check-out processes
- Booking status tracking

### 4. Payment Management
- Monthly rent collection and tracking
- Security deposit management
- Payment history and digital receipts
- Late payment notifications and alerts
- Multiple payment methods integration
- Revenue analytics and reporting

### 5. Resident Services
- Complaint and maintenance request system
- Visitor management and registration
- Digital notice board and announcements
- Meal plan management (optional)
- Personal profile management

### 6. Reporting & Analytics
- Real-time occupancy reports
- Revenue and financial analytics
- Maintenance cost tracking
- Resident demographics and statistics
- Custom report generation

## 🗄️ Supabase Database Schema

### Core Tables Structure

#### 1. User Profiles
```sql
profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  full_name TEXT NOT NULL,
  phone VARCHAR(15),
  email TEXT UNIQUE NOT NULL,
  role user_role NOT NULL DEFAULT 'resident',
  avatar_url TEXT,
  emergency_contact TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### 2. Hostels
```sql
hostels (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  phone VARCHAR(15),
  email TEXT,
  total_rooms INTEGER DEFAULT 0,
  total_beds INTEGER DEFAULT 0,
  manager_id UUID REFERENCES profiles(id),
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### 3. Room Types
```sql
room_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL, -- 'Single', 'Double', 'Dormitory'
  capacity INTEGER NOT NULL,
  monthly_rent DECIMAL(10,2) NOT NULL,
  security_deposit DECIMAL(10,2) NOT NULL,
  amenities TEXT[], -- Array of amenities
  hostel_id UUID REFERENCES hostels(id)
);
```

#### 4. Rooms
```sql
rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_number VARCHAR(10) NOT NULL,
  floor INTEGER,
  room_type_id UUID REFERENCES room_types(id),
  hostel_id UUID REFERENCES hostels(id),
  status room_status DEFAULT 'available',
  last_maintenance DATE,
  next_maintenance DATE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### 5. Beds
```sql
beds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bed_number VARCHAR(5) NOT NULL,
  room_id UUID REFERENCES rooms(id),
  is_occupied BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### 6. Bookings/Reservations
```sql
bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resident_id UUID REFERENCES profiles(id),
  room_id UUID REFERENCES rooms(id),
  bed_id UUID REFERENCES beds(id) NULL,
  check_in_date DATE NOT NULL,
  check_out_date DATE,
  monthly_rent DECIMAL(10,2) NOT NULL,
  security_deposit DECIMAL(10,2) NOT NULL,
  status booking_status DEFAULT 'active',
  contract_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### 7. Payments
```sql
payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID REFERENCES bookings(id),
  amount DECIMAL(10,2) NOT NULL,
  payment_type payment_type NOT NULL,
  payment_method VARCHAR(50),
  payment_date DATE NOT NULL,
  due_date DATE,
  status payment_status DEFAULT 'pending',
  receipt_url TEXT,
  transaction_id TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### 8. Maintenance Requests
```sql
maintenance_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID REFERENCES rooms(id),
  resident_id UUID REFERENCES profiles(id),
  title TEXT NOT NULL,
  description TEXT,
  priority priority_level DEFAULT 'medium',
  status request_status DEFAULT 'pending',
  assigned_to UUID REFERENCES profiles(id),
  estimated_cost DECIMAL(10,2),
  actual_cost DECIMAL(10,2),
  images TEXT[], -- Array of image URLs
  created_at TIMESTAMP DEFAULT NOW(),
  resolved_at TIMESTAMP
);
```

#### 9. Visitors
```sql
visitors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resident_id UUID REFERENCES profiles(id),
  visitor_name TEXT NOT NULL,
  visitor_phone VARCHAR(15),
  visitor_id_number VARCHAR(20),
  purpose TEXT,
  check_in_time TIMESTAMP NOT NULL,
  expected_checkout TIMESTAMP,
  actual_checkout TIMESTAMP,
  approved_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### 10. Announcements
```sql
announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hostel_id UUID REFERENCES hostels(id),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  priority priority_level DEFAULT 'medium',
  target_audience user_role[] DEFAULT '{resident}',
  created_by UUID REFERENCES profiles(id),
  expires_at TIMESTAMP,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Custom Types (Enums)
```sql
CREATE TYPE user_role AS ENUM ('admin', 'manager', 'staff', 'resident', 'guest');
CREATE TYPE room_status AS ENUM ('available', 'occupied', 'maintenance', 'reserved');
CREATE TYPE booking_status AS ENUM ('active', 'expired', 'cancelled', 'pending');
CREATE TYPE payment_type AS ENUM ('rent', 'deposit', 'fine', 'refund', 'utility');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'overdue');
CREATE TYPE request_status AS ENUM ('pending', 'in_progress', 'completed', 'cancelled');
CREATE TYPE priority_level AS ENUM ('low', 'medium', 'high', 'urgent');
```

## 📱 App Flow Structure

### Authentication Flow
```
Splash Screen → Login/Register → Role Verification → Dashboard
```

### Admin/Manager Flow
```
Dashboard
├── Room Management
│   ├── Add/Edit Rooms
│   ├── View Availability
│   └── Maintenance Schedule
├── Resident Management
│   ├── All Residents
│   ├── Booking History
│   └── Payment Status
├── Payment Tracking
│   ├── Collect Payments
│   ├── Generate Receipts
│   └── Overdue Reports
├── Maintenance
│   ├── View Requests
│   ├── Assign Tasks
│   └── Cost Tracking
└── Reports & Analytics
    ├── Occupancy Reports
    ├── Revenue Analytics
    └── Custom Reports
```

### Staff Flow
```
Dashboard
├── Check-in/Check-out
├── Visitor Management
├── Maintenance Tasks
└── Daily Reports
```

### Resident Flow
```
Dashboard
├── Personal Profile
├── Payment History
├── Maintenance Requests
├── Visitor Registration
├── Announcements
└── Support/Help
```

## 🔄 Database Relationships & Flow

### Key Relationships
- `hostels` (1) → (many) `rooms` → (many) `beds`
- `profiles` (1) → (many) `bookings` → (many) `payments`
- `rooms` (1) → (many) `maintenance_requests`
- `profiles` (1) → (many) `visitors`
- `hostels` (1) → (many) `announcements`

### Row Level Security (RLS) Policies
- **Residents**: Access only their own data and public announcements
- **Staff**: Access hostel-specific operational data
- **Managers**: Full access to their hostel's data and analytics
- **Admins**: System-wide access and configuration

## 🚀 Development Phases

### Phase 1: Foundation (Week 1-2)
- [ ] Set up Supabase project and database
- [ ] Create all database tables and relationships
- [ ] Set up Flutter project structure
- [ ] Implement authentication system
- [ ] Create basic UI components and themes

### Phase 2: Core Features (Week 3-4)
- [ ] User role management and permissions
- [ ] Room and bed management system
- [ ] Basic booking and reservation system
- [ ] Payment tracking foundation

### Phase 3: Advanced Features (Week 5-6)
- [ ] Maintenance request system
- [ ] Visitor management
- [ ] Announcement system
- [ ] Basic reporting and analytics

### Phase 4: Polish & Testing (Week 7-8)
- [ ] UI/UX improvements
- [ ] Performance optimization
- [ ] Testing and bug fixes
- [ ] Documentation and deployment

## 🛠️ Technical Stack

### Frontend
- **Flutter**: Cross-platform mobile development
- **Provider/Riverpod**: State management
- **Flutter Hooks**: Lifecycle management

### Backend
- **Supabase**: Backend-as-a-Service
- **PostgreSQL**: Database
- **Row Level Security**: Data access control
- **Supabase Auth**: Authentication and authorization

### Additional Services
- **Supabase Storage**: File and image storage
- **Supabase Edge Functions**: Custom business logic
- **Push Notifications**: Real-time updates

## 📋 Next Steps

1. **Database Setup**: Create Supabase project and implement schema
2. **Flutter Setup**: Configure project dependencies and folder structure
3. **Authentication**: Implement login/register with role-based access
4. **Core UI**: Design and implement main navigation and dashboards
5. **Feature Implementation**: Build features incrementally following the phases

## 📝 Notes
- Consider implementing offline capability for critical features
- Plan for multi-language support if needed
- Ensure GDPR compliance for user data handling
- Implement proper error handling and user feedback
- Consider implementing push notifications for important updates

---
*Last Updated: July 27, 2025*
*Project: Hostel Management App*
*Tech Stack: Flutter + Supabase*
