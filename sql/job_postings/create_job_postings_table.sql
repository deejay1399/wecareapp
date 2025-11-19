-- Create job_postings table for storing job postings by employers
CREATE TABLE IF NOT EXISTS job_postings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    employer_id UUID NOT NULL REFERENCES employers(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    payment_frequency VARCHAR(50) NOT NULL CHECK (payment_frequency IN ('Per Hour', 'Per Day', 'Per Week', 'bi weekly', 'Per Month')),
    barangay VARCHAR(100) NOT NULL,
    required_skills TEXT[] NOT NULL DEFAULT '{}',
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'closed', 'filled', 'in progress', 'completed')),
    applications_count INTEGER DEFAULT 0,
    assigned_helper_id UUID REFERENCES helpers(id) ON DELETE SET NULL,
    assigned_helper_name VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_job_postings_employer_id ON job_postings(employer_id);
CREATE INDEX IF NOT EXISTS idx_job_postings_status ON job_postings(status);
CREATE INDEX IF NOT EXISTS idx_job_postings_barangay ON job_postings(barangay);
CREATE INDEX IF NOT EXISTS idx_job_postings_created_at ON job_postings(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_job_postings_assigned_helper_id ON job_postings(assigned_helper_id);

-- Create function for updated_at trigger (if not exists)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create updated_at trigger (drop first if exists)
DROP TRIGGER IF EXISTS update_job_postings_updated_at ON job_postings;
CREATE TRIGGER update_job_postings_updated_at 
    BEFORE UPDATE ON job_postings 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();
