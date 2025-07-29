-- 1. Create the profiles table
-- This table stores public user data.
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'resident',
  avatar_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Set up Row Level Security (RLS)
-- This ensures that users can only access their own data.
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Create RLS policies for the profiles table

-- Policy: Users can see their own profile
CREATE POLICY "Users can view their own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can create their own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- Optional: Add a trigger to automatically update the 'updated_at' timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at() 
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_profile_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_updated_at();

-- 5. Create Rooms, Beds, Bookings, Payments, and Maintenance Requests Tables

-- Create Rooms Table
CREATE TABLE public.rooms (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    room_number TEXT NOT NULL UNIQUE,
    room_type TEXT NOT NULL, -- e.g., 'single', 'double', 'triple', 'quad', 'dormitory'
    capacity INT NOT NULL,
    price_per_semester DECIMAL(10, 2) NOT NULL,
    description TEXT,
    staff_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'available', -- 'available', 'occupied', 'maintenance'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create Beds Table
CREATE TABLE public.beds (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    room_id BIGINT NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
    bed_number TEXT NOT NULL, -- e.g., 'A', 'B', '1', '2'
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE(room_id, bed_number)
);

-- Create Bookings Table
CREATE TABLE public.bookings (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    resident_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    room_id BIGINT NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
    bed_id BIGINT NOT NULL REFERENCES public.beds(id) ON DELETE CASCADE,
    check_in_date DATE NOT NULL,
    check_out_date DATE,
    status TEXT NOT NULL DEFAULT 'active', -- e.g., 'active', 'completed', 'cancelled'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create Payments Table
CREATE TABLE public.payments (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    booking_id BIGINT NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_type TEXT NOT NULL, -- e.g., 'rent', 'deposit', 'fine'
    status TEXT NOT NULL DEFAULT 'completed', -- e.g., 'completed', 'pending', 'failed'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create Maintenance Requests Table
CREATE TABLE public.maintenance_requests (
    id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    booking_id BIGINT NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    category TEXT NOT NULL, -- e.g., 'Plumbing', 'Electrical', 'General'
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending', -- e.g., 'pending', 'in_progress', 'completed'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- 6. Create Announcements Table
CREATE TABLE public.announcements (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  author_id UUID REFERENCES public.profiles(id)
);

-- 7. Add RLS Policies for all new tables

-- Rooms RLS
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can view available rooms (for residents to book)
CREATE POLICY "Users can view available rooms" ON public.rooms 
  FOR SELECT USING (status = 'available');

-- Policy: Staff can view their own rooms
CREATE POLICY "Staff can view their own rooms" ON public.rooms 
  FOR SELECT USING (staff_id = auth.uid() AND (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'staff');

-- Policy: Staff can insert their own rooms
CREATE POLICY "Staff can create rooms" ON public.rooms 
  FOR INSERT WITH CHECK (staff_id = auth.uid() AND (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'staff');

-- Policy: Staff can update their own rooms
CREATE POLICY "Staff can update their own rooms" ON public.rooms 
  FOR UPDATE USING (staff_id = auth.uid() AND (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'staff');

-- Policy: Staff can delete their own rooms
CREATE POLICY "Staff can delete their own rooms" ON public.rooms 
  FOR DELETE USING (staff_id = auth.uid() AND (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'staff');

-- Policy: Admins can manage all rooms
CREATE POLICY "Admins can manage all rooms" ON public.rooms 
  FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Beds RLS
ALTER TABLE public.beds ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can view beds" ON public.beds FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Admins can manage beds" ON public.beds FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Bookings RLS
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own bookings" ON public.bookings FOR SELECT USING (auth.uid() = resident_id);
CREATE POLICY "Users can create their own bookings" ON public.bookings FOR INSERT WITH CHECK (auth.uid() = resident_id);
CREATE POLICY "Admins can view all bookings" ON public.bookings FOR SELECT USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');
CREATE POLICY "Admins can update bookings" ON public.bookings FOR UPDATE USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Payments RLS
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own payments" ON public.payments FOR SELECT USING (
    (SELECT resident_id FROM public.bookings WHERE id = booking_id) = auth.uid()
);
CREATE POLICY "Admins can view all payments" ON public.payments FOR SELECT USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Maintenance Requests RLS
ALTER TABLE public.maintenance_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own maintenance requests" ON public.maintenance_requests FOR SELECT USING (
    (SELECT resident_id FROM public.bookings WHERE id = booking_id) = auth.uid()
);
CREATE POLICY "Users can create their own maintenance requests" ON public.maintenance_requests FOR INSERT WITH CHECK (
    (SELECT resident_id FROM public.bookings WHERE id = booking_id) = auth.uid()
);
CREATE POLICY "Admins can manage maintenance requests" ON public.maintenance_requests FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- Announcements RLS
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Authenticated users can view announcements" ON public.announcements FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Admins can manage announcements" ON public.announcements FOR ALL USING ((SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin');

-- 8. Create Stored Procedure for Booking
CREATE OR REPLACE FUNCTION public.create_booking_and_update_bed(
    p_resident_id UUID,
    p_room_id UUID,
    p_bed_id UUID
)
RETURNS void AS $$
DECLARE
    v_rent_amount DECIMAL;
BEGIN
    -- Fetch rent amount from rooms table
    SELECT rent_amount INTO v_rent_amount
    FROM public.rooms
    WHERE id = p_room_id;

    -- Create the new booking with pending status and fetched rent amount
    INSERT INTO public.bookings (resident_id, room_id, bed_id, check_in_date, status, monthly_rent)
    VALUES (p_resident_id, p_room_id, p_bed_id, CURRENT_DATE, 'pending', v_rent_amount);

    -- Note: Bed availability is not updated until booking is approved
END;
$$ LANGUAGE plpgsql;

-- 9. Messages Table
CREATE TABLE public.messages (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies for Messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own messages" ON public.messages
FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

CREATE POLICY "Users can send messages" ON public.messages
FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- 10. Function to get staff members
CREATE OR REPLACE FUNCTION public.get_staff_members(p_user_id UUID)
RETURNS TABLE(id UUID, full_name TEXT, role TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT p.id, p.full_name, p.role
    FROM public.profiles p
    WHERE (p.role = 'admin' OR p.role = 'staff') AND p.id <> p_user_id;
END;
$$ LANGUAGE plpgsql;
