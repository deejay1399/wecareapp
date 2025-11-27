# Reports System Setup Instructions

## Overview
The reporting system allows employers and helpers to report suspicious activity, inappropriate content, or other violations. Admin can view and manage all reports from the admin panel.

## Database Setup

### 1. Run SQL Migration
Execute the following SQL script in your Supabase database:
- SQL file location: `sql/reports/create_reports_table.sql`

This will create:
- `reports` table with all necessary columns
- Indexes for optimized querying  
- Row Level Security (RLS) policies

### Table Structure
```sql
reports (
  id UUID (Primary Key),
  reported_by UUID (who submitted the report),
  reported_user UUID (who is being reported),
  reason VARCHAR(100),
  type VARCHAR(50) - 'job_posting', 'service_posting', 'job_application',
  reference_id UUID (ID of the reported item),
  description TEXT,
  status VARCHAR(50) - 'pending', 'under_review', 'resolved', 'dismissed',
  admin_notes TEXT,
  reporter_name VARCHAR(255),
  reported_user_name VARCHAR(255),
  created_at TIMESTAMP,
  updated_at TIMESTAMP
)
```

## Components Created

### 1. Models
- **`lib/models/report.dart`** - Report data model with JSON serialization

### 2. Services
- **`lib/services/report_service.dart`** - Service for CRUD operations:
  - `submitReport()` - Submit a new report
  - `getAllReports()` - Get all reports (admin)
  - `getReportsForUser()` - Get reports about a specific user
  - `getReportsByReference()` - Get reports for a specific job/service/application
  - `updateReportStatus()` - Update report status (admin)
  - `hasAlreadyReported()` - Check if user already reported this item
  - `getReportStatistics()` - Get report stats for admin dashboard

### 3. Widgets
- **`lib/widgets/dialogs/report_dialog.dart`** - Reusable dialog for submitting reports
  - Shows reason dropdown with predefined options
  - Text field for detailed description
  - Submit and cancel buttons

### 4. Admin Screens
- **`lib/screens/admin/admin_reports_page.dart`** - Admin page to view and manage reports:
  - Filter reports by status (pending, under_review, resolved, dismissed)
  - Filter reports by type (job_posting, service_posting, job_application)
  - View report details in modal
  - Update report status
  - View admin notes

### 5. Translations
Added to all language files (en.json, tl.json, ceb.json):
- `report` - "Report"
- `report_this_item` - "Report This Item"
- `help_us_keep_platform_safe` - Help text
- `reason`, `description`, `submit_report` - Form fields
- Report reason options: `inappropriate_content`, `suspicious_activity`, `unprofessional_behavior`, `non_payment_scam`, `harassment`, `other`

## Integration Instructions

To fully integrate the reporting system, you need to:

### 1. Add Report Button to Job Posting Card
File: `lib/widgets/cards/job_posting_card.dart`

Add a report button in the card header or action buttons:
```dart
IconButton(
  icon: const Icon(Icons.flag_outlined),
  onPressed: () => _showReportDialog(context, 'job_posting', jobPosting.id),
  tooltip: 'Report this job posting',
)
```

### 2. Add Report Button to Service Posting Card  
File: `lib/widgets/cards/helper_service_posting_card.dart`

Same implementation as job posting card but with type: `'service_posting'`

### 3. Add Report Button to Job Application Screen
File: `lib/screens/employer/application_details_screen.dart` or similar

Add a report button when viewing an application:
```dart
IconButton(
  icon: const Icon(Icons.flag_outlined),
  onPressed: () => _showReportDialog(context, 'job_application', application.id),
  tooltip: 'Report this application',
)
```

### 4. Add Reports Tab to Admin Panel
Update `lib/screens/admin/admin_main.dart` (or wherever admin tabs are):

```dart
Tab(text: 'Reports', icon: Icon(Icons.flag)),
// Then add:
admin_reports_page.dart // to the tab view
```

### 5. Helper Method to Show Report Dialog
Add this method to any screen that needs reporting:

```dart
void _showReportDialog(BuildContext context, String type, String referenceId) async {
  final reported = await _getCurrentUser(); // Get current user
  final reportedUser = await _getReportedUser(referenceId); // Get user being reported
  
  showDialog(
    context: context,
    builder: (context) => ReportDialog(
      type: type,
      onSubmit: (reason, description) async {
        try {
          await ReportService.submitReport(
            reportedBy: reported.id,
            reportedUser: reportedUser.id,
            reason: reason,
            type: type,
            referenceId: referenceId,
            description: description,
            reporterName: '${reported.firstName} ${reported.lastName}',
            reportedUserName: '${reportedUser.firstName} ${reportedUser.lastName}',
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationManager.translate(
                'report_submitted_successfully',
              )),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocalizationManager.translate(
                'failed_to_submit_report',
              )),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    ),
  );
}
```

## Report Status Workflow

1. **pending** - New report submitted, awaiting admin review
2. **under_review** - Admin is reviewing the report
3. **resolved** - Action has been taken (user blocked, content removed, etc.)
4. **dismissed** - Report was reviewed and no action needed

## Features

✅ Report submission with predefined reasons  
✅ Detailed description text field  
✅ Prevents duplicate reports from same user  
✅ Admin dashboard to view all reports  
✅ Filter reports by status and type  
✅ View full report details with notes  
✅ Multi-language support (English, Tagalog, Cebuano)  
✅ RLS security policies for data protection  

## Testing Checklist

- [ ] Run SQL migration to create reports table
- [ ] Test submitting a report from different user types
- [ ] Verify admin can view all reports
- [ ] Test filtering reports by status and type
- [ ] Test updating report status from admin panel
- [ ] Verify duplicate report prevention works
- [ ] Test translations in all 3 languages
- [ ] Verify reports appear in admin dashboard

## Future Enhancements

- Automated actions (auto-block users with many reports)
- Email notifications to admin when new reports submitted
- Report history and audit trail
- Appeal system for users
- Public list of violations/warnings
