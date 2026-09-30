# Creator Yard

**Offline-first POS and inventory management for retail businesses.**

Creator Yard is a Flutter-based retail management platform built for businesses that need their core operations to continue working directly on the device, even when internet connectivity is unavailable or unreliable.

The application uses a local **SQLite database through Drift** for day-to-day retail operations. External services are used for specific connected capabilities such as installation registration, commercial licensing, transactional email and email-credit purchases.

---

## Platform Overview

Creator Yard brings together:

* Point of Sale
* Product and inventory management
* Stock receiving and adjustments
* Physical stock verification
* Supplier purchasing and payable tracking
* Staff and employee management
* User roles and permissions
* Attendance
* Staff purchases and employee debt
* Sales and inventory reporting
* PDF report exports
* Receipt generation and printing
* Transactional email
* Email credits
* Local database backup and restore
* Installation registration
* Demo and commercial licensing

---

## Point of Sale

The POS supports configurable payment methods including:

* Cash
* POS/card
* Bank transfer
* Split payments

Split payments allow a sale to be completed using multiple enabled payment methods.

The sales workflow also supports:

* Product search and selection
* Discounts
* Customer information
* Cash received and change calculation
* Payment breakdowns
* Cashier information
* Receipt numbers
* Completed-sale persistence
* Customer receipt email

Completed sales are stored locally in the application database.

---

## Products & Inventory

Creator Yard provides product and category management together with stock control.

### Products

* Create, edit and delete products
* Product name and brand
* Cost and selling prices
* Categories
* Product images
* Current stock
* Low-stock thresholds
* Product search and filtering
* Product history

### Categories

* Create, edit and delete categories
* Category images
* Product organization

### Stock Operations

* Receive stock
* Stock adjustments
* Stock movement history
* Product stock ledger
* Low-stock monitoring
* Out-of-stock monitoring
* Inventory valuation
* Physical stock verification

### Stock Verification

Physical stock verification provides a review workflow:

1. Start a stock verification
2. Capture expected system quantities
3. Enter physical counts
4. Calculate variances
5. Submit for review
6. Approve or reject the verification
7. Apply approved stock adjustments

Verification access is controlled through employee permissions.

---

## Suppliers & Purchasing

Supplier management is an optional part of the platform for businesses that need purchasing and payable tracking.

The supplier module supports:

* Supplier records
* Supplier deliveries
* Delivery items
* Supplier payments
* Payment allocation
* Unallocated payments
* Outstanding balances
* Fully paid deliveries
* Supplier statements
* Purchase totals
* Payment totals
* Outstanding supplier balances
* Allocation history
* Supplier-related stock adjustments

Businesses that do not require supplier tracking can operate without using this module.

---

## Staff & Users

Creator Yard includes user accounts and employee management.

### Roles

The application supports:

* Owner
* Manager
* Staff

### Employee Management

* Create employee accounts
* Active/inactive employee status
* Employee profiles
* Employee permissions
* Password management
* Employment information
* Salary information
* Employee contact information

### Attendance

* Staff attendance
* Attendance history

### Staff Purchases & Debt

Employees can have purchases recorded as:

* Cash purchases
* Credit purchases

The system also tracks staff debt and debt payments.

---

## Reports & Business Intelligence

Creator Yard includes a reporting module covering sales, revenue, profitability, inventory and staff activity.

Available reports include:

* Sales reports
* Gross revenue
* Profit
* Items sold
* Category performance
* Stock value
* Low stock
* Out of stock
* Expiry
* Salary and debt
* Daily reconciliation

The reporting dashboard also provides visualizations such as:

* Sales trends
* Payment breakdowns
* Category performance

### Report Export

Reports can be exported as PDF files.

The application also provides a daily report service capable of producing a local JSON report snapshot.

### Report Email

PDF reports can be emailed to a selected recipient.

The business email can be used as the default recipient.

Report email delivery uses Creator Yard Email Credits.

---

## Receipts & Printing

Creator Yard generates PDF-based receipts containing configurable business and transaction information.

Receipt configuration includes:

* Business identity
* Business logo
* Receipt date and time
* Receipt number
* Cashier
* Tax
* Discount
* Payment breakdown
* Receipt footer
* Paper size

Receipt PDFs can be printed through Flutter's PDF printing integration.

Customer receipts can also be emailed as PDF attachments when customer receipt email is enabled.

---

## Business Configuration

Businesses can configure their identity and operational preferences.

Business information includes:

* Business name
* Logo
* Tagline
* Phone
* Email
* Address
* Business type

Additional configuration includes:

* POS settings
* Payment methods
* Receipt settings
* Report settings
* Appearance
* Security settings
* Email settings

---

## Offline-First Architecture

Core retail data is stored locally using SQLite and Drift.

```text
                    Creator Yard

                         │
              ┌──────────┴──────────┐
              │                     │
       Local Application      Connected Services
              │                     │
        SQLite + Drift       Installation Registration
              │               Commercial Licensing
              │               Transactional Email
              │               Email Credits
              │
     ┌────────┼─────────┐
     │        │         │
    POS   Inventory   Staff
     │        │         │
   Sales   Products   Employees
           Suppliers  Attendance
           Reports   Settings
```

Internet connectivity is therefore not required for the application's core local retail database operations.

Connected functionality depends on the relevant external service being available.

Creator Yard currently does **not** implement a general cloud database synchronization layer.

---

## Data Backup & Restore

Creator Yard provides local SQLite database backup and restore.

### Automatic Backup

The application creates one automatic database backup per calendar day.

Backups are stored locally and retained up to **7 backups**.

SQLite's `VACUUM INTO` mechanism is used to create consistent database snapshots while the application database remains open.

### Manual Backup

Users can create an additional backup from:

**Settings → Backup & Data**

### Restore

Before restoring a database:

1. The selected backup is validated.
2. SQLite integrity is checked.
3. A safety backup of the current database is created.
4. The selected database replaces the live database.
5. The restored database is validated again.

This keeps the current database recoverable if restoration fails.

---

## Installation & Licensing

Creator Yard uses a persistent installation identity.

Each installation receives a unique UUID that is stored locally and reused by the platform.

The installation can register with the Creator Yard backend, which provides an installation credential used by connected services.

### Demo

A new installation receives a **14-day demo period**.

The demo state is stored locally and includes protection against significant system-clock rollback.

The demo does not require a separate customer build.

### Commercial Activation

Commercial licensing is server-authoritative.

The normal customer flow is:

```text
Install Creator Yard
        ↓
Installation receives an ID
        ↓
Installation registers
        ↓
14-day demo begins
        ↓
Installation appears in Creator Yard administration
        ↓
Administrator activates the installation
        ↓
Application detects commercial license
        ↓
Same installation continues as licensed
```

Activation does not require the customer to uninstall the application, delete its database or select a different build type.

The `CREATOR_YARD_COMMERCIAL` build define exists for internal development/testing of the commercial provider and is not the customer-facing licensing workflow.

---

## Transactional Email

Creator Yard integrates with the Creator Yard Email API for connected email functionality.

Supported email operations include:

* Sale emails
* Customer receipt emails
* Report emails

Sale emails are queued locally so that an email failure does not prevent a completed sale from being recorded.

Pending sale-email jobs can be processed and retried independently of the completed retail transaction.

---

## Email Credits

Transactional email uses Creator Yard Email Credits.

The application can:

* View available email credit packages
* Purchase credits
* View current balance
* View credit usage history
* Configure low-credit warnings

Credit purchases use a server-controlled payment checkout flow.

Email-credit availability is separate from the local retail transaction database.

---

## Technology

Creator Yard is built with:

* **Flutter**
* **Dart**
* **SQLite**
* **Drift**
* **Cloudflare Worker-backed services**
* **PDF generation**
* **PDF printing**
* **HTTP APIs**
* **UUID-based installation identity**

The application is structured into feature modules with a local database layer, shared core services and platform-specific UI components.

---

## Project Structure

```text
lib/
├── core/
│   ├── backup/
│   ├── business/
│   ├── email/
│   ├── licensing/
│   ├── navigation/
│   ├── pos/
│   ├── responsive/
│   ├── router/
│   ├── system/
│   └── theme/
│
├── database/
│   ├── daos/
│   ├── models/
│   ├── tables/
│   └── app_database.dart
│
├── features/
│   ├── attendance/
│   ├── category/
│   ├── dashboard/
│   ├── inventory/
│   ├── licensing/
│   ├── products/
│   ├── reports/
│   ├── sales/
│   ├── settings/
│   ├── staff/
│   ├── stocks/
│   ├── suppliers/
│   └── users/
│
└── shared/
```

---

## Development

Creator Yard is being developed as a commercial retail platform and as an extensible developer project.

The codebase is organized so that developers, implementation partners and technology partners can work on individual platform areas without requiring the entire application architecture to be rewritten.

Core retail functionality remains local, while connected services are isolated behind dedicated service and provider layers.

---

## Support

**WhatsApp:** https://wa.me/message/RXSBYEJYFFH6P1
Send Austin Arcex a message on WhatsApp.

Creator Yard is under active development, so platform capabilities and supported deployment targets may continue to expand.
