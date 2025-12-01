# Supabase Database Migration Guide: Barangay Clearance → Police Clearance

## Overview
This document outlines the database changes needed to transition from **Barangay Clearance** to **Police Clearance** with expiration date validation.

## Database Changes Required

### 1. **Employers Table**

#### New Columns to Add:
```sql
ALTER TABLE employers
ADD COLUMN IF NOT EXISTS police_clearance_base64 TEXT,
ADD COLUMN IF NOT EXISTS police_clearance_expiry_date VARCHAR(50);
```

#### Migrate Existing Data:
```sql
UPDATE employers 
SET police_clearance_base64 = barangay_clearance_base64
WHERE barangay_clearance_base64 IS NOT NULL;
```

#### Add Indexes for Performance:
```sql
CREATE INDEX IF NOT EXISTS idx_employers_police_clearance_expiry 
ON employers(police_clearance_expiry_date);
```

#### Column Details:
| Column | Type | Description |
|--------|------|-------------|
| `police_clearance_base64` | TEXT | Base64 encoded police clearance image |
| `police_clearance_expiry_date` | VARCHAR(50) | Extracted expiration date (format varies: DD/MM/YYYY, YYYY-MM-DD, or text format) |

---

### 2. **Helpers Table**

#### New Columns to Add:
```sql
ALTER TABLE helpers
ADD COLUMN IF NOT EXISTS police_clearance_base64 TEXT,
ADD COLUMN IF NOT EXISTS police_clearance_expiry_date VARCHAR(50);
```

#### Migrate Existing Data:
```sql
UPDATE helpers
SET police_clearance_base64 = barangay_clearance_base64
WHERE barangay_clearance_base64 IS NOT NULL;
```

#### Add Indexes for Performance:
```sql
CREATE INDEX IF NOT EXISTS idx_helpers_police_clearance_expiry 
ON helpers(police_clearance_expiry_date);
```

#### Column Details:
| Column | Type | Description |
|--------|------|-------------|
| `police_clearance_base64` | TEXT | Base64 encoded police clearance image |
| `police_clearance_expiry_date` | VARCHAR(50) | Extracted expiration date (format varies) |

---

## Migration Files Location

Pre-made SQL migration files are available:
- **Employers Migration**: `/sql/employer/migrate_barangay_to_police_clearance.sql`
- **Helpers Migration**: `/sql/helper/migrate_barangay_to_police_clearance.sql`

## Backward Compatibility

The old `barangay_clearance_base64` column will be **retained** for backward compatibility during the transition period. It can be safely removed in a future migration once all applications are updated.

## Application-Side Changes

### Dart Models Updated
- `Employer` model: `barangayClearanceBase64` → `policeClearanceBase64` + `policeClearanceExpiryDate`
- `Helper` model: `barangayClearanceBase64` → `policeClearanceBase64` + `policeClearanceExpiryDate`

### Services Updated
- `EmployerAuthService.registerEmployer()`: New parameters for police clearance
- `EmployerAuthService.updateEmployerProfile()`: Supports police clearance updates
- `HelperAuthService.registerHelper()`: New parameters for police clearance
- `HelperAuthService.updateHelperProfile()`: Supports police clearance updates

### UI Changes
- **Employer Registration**: Police Clearance verification with expiration check
- **Helper Registration**: Police Clearance verification with expiration check
- **AI Verification**: Extracts expiration date and validates it's not expired

## AI Verification Logic

The application now:
1. Extracts text from police clearance image using OCR
2. Looks for keywords: "police" or "nbi" AND "clearance"
3. Matches user's name from the form
4. **Extracts expiration date** using regex patterns (supports DD/MM/YYYY, YYYY-MM-DD, and text formats)
5. **Validates expiration date** - must be in the future
6. **Calculates confidence score** including expiration validity
7. **Rejects verification** if clearance is expired with clear error message

## Date Format Support

The system extracts dates in these formats:
- `DD/MM/YYYY` (e.g., "15/01/2025")
- `DD-MM-YYYY` (e.g., "15-01-2025")
- `YYYY-MM-DD` (e.g., "2025-01-15")
- `YYYY/MM/DD` (e.g., "2025/01/15")
- Text format: `(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)*.* DD, YYYY`

## Deployment Steps

1. **Backup Database**: Create a database backup before running migrations
2. **Run Employer Migration**: Execute the employer migration SQL
3. **Run Helper Migration**: Execute the helper migration SQL
4. **Verify Data**: Check that data migrated correctly
5. **Deploy Updated App**: Deploy the updated Flutter application with new police clearance logic
6. **Monitor**: Monitor for any issues during the transition

## Rollback Plan (If Needed)

To rollback (before removing old columns):
```sql
-- For employers
UPDATE employers 
SET police_clearance_base64 = NULL
WHERE police_clearance_base64 IS NOT NULL;

-- For helpers
UPDATE helpers
SET police_clearance_base64 = NULL
WHERE police_clearance_base64 IS NOT NULL;
```

The old `barangay_clearance_base64` column still contains the original data, so rollback is possible.

## Future: Cleanup Migration

After confirming all clients are updated (future migration):
```sql
-- Remove old barangay_clearance columns
ALTER TABLE employers DROP COLUMN IF EXISTS barangay_clearance_base64;
ALTER TABLE helpers DROP COLUMN IF EXISTS barangay_clearance_base64;
```

---

## Summary of Changes

| Aspect | Before | After |
|--------|--------|-------|
| Document Type | Barangay Clearance | Police Clearance |
| Columns | `barangay_clearance_base64` | `police_clearance_base64` + `police_clearance_expiry_date` |
| Keyword Detection | "barangay" + "clearance" | "police"/"nbi" + "clearance" |
| Expiration Check | ❌ No | ✅ Yes (AI extracts and validates) |
| Confidence Scoring | 30% keywords + 50% name match | 30% keywords + 30% name match + 30% not expired |
| Error Handling | Generic failure message | Specific: "Clearance has expired. Please provide valid, non-expired clearance." |
