# Creator Yard

**Offline-first POS and inventory management for retail businesses.**

Creator Yard is a Flutter-based retail management system designed to run locally on computers, tablets, POS terminals and other supported devices.

The application is built around a local SQLite database so that core retail operations can continue without depending on a permanent internet connection.

The project is being developed as an extensible commercial product and as an open developer platform where developers, implementation partners and technology partners can help improve, deploy and extend the system.

---

## What Creator Yard Does

Creator Yard brings day-to-day retail operations into one application.

### Point of Sale

* Cash payments
* POS/card payments
* Bank transfer payments
* Split payments
* Discounts
* Customer information
* Configurable payment methods
* Optional price editing during sales
* Receipt generation
* Receipt printing
* Transactional email receipts

### Products & Inventory

* Product management
* Categories
* Product images
* Stock quantities
* Stock movements
* Stock receiving
* Stock adjustments
* Low-stock monitoring
* Out-of-stock reporting
* Inventory valuation
* Product history

### Suppliers

* Supplier management
* Supplier deliveries
* Supplier delivery items
* Supplier payments
* Supplier payment allocation
* Supplier statements
* Supplier credit
* Partial payments
* Overpayment controls
* Supplier configuration rules

### Staff & Users

* User accounts
* User profiles
* Staff management
* Attendance
* Staff purchases
* Staff debt management
* User permissions and security settings

### Reports

Current reporting functionality includes:

* Sales reports
* Daily reports
* Gross revenue reports
* Profit reports
* Items sold
* Category reports
* Stock value
* Low-stock reports
* Out-of-stock reports
* Expiry reports
* Salary reports
* Reconciliation
* Report snapshots and exports

### Receipts

Receipt configuration supports:

* 58mm receipt layouts
* 80mm receipt layouts
* A4 receipts
* Business identity
* Logo
* Address
* Phone
* Business email
* Receipt footer
* Receipt number
* Date/time
* Tax
* Discounts
* Printing configuration

### Business Configuration

Each installation can configure its own business identity and operating preferences without changing the application itself.

This allows the same Creator Yard application to serve different retail businesses.

---

# Why Creator Yard Is Offline-First

The core application does not require a permanent internet connection.

The local device maintains the operational database using:

* Flutter
* Drift
* SQLite

This means sales, inventory, products, suppliers, staff and other core operations can continue locally.

Internet connectivity is used for features that specifically require external services, such as:

* Email Credits
* Transactional email
* Licensing services
* Online payments
* Future synchronization services

This architecture is especially important for retail environments where internet connectivity may be unreliable.

---

# Technology Stack

| Area             | Technology         |
| ---------------- | ------------------ |
| Application      | Flutter            |
| Language         | Dart               |
| Local database   | SQLite             |
| Database layer   | Drift              |
| Routing          | go_router          |
| UI               | Flutter Material   |
| Fonts            | Poppins            |
| Charts           | fl_chart           |
| PDF              | pdf                |
| Printing         | printing           |
| Networking       | http               |
| External backend | Cloudflare Workers |
| Backend database | Cloudflare D1      |
| Email delivery   | Resend             |
| Payments         | Flutterwave        |

---

# Project Architecture

The project is organized around application features, shared core services and a local database layer.

```text
lib/
├── core/
│   ├── business/
│   ├── email/
│   ├── licensing/
│   ├── navigation/
│   ├── pos/
│   ├── responsive/
│   ├── router/
│   ├── system/
│   ├── theme/
│   └── widgets/
│
├── database/
│   ├── daos/
│   ├── models/
│   ├── tables/
│   ├── app_database.dart
│   ├── business_settings.dart
│   └── supplier_settings.dart
│
└── features/
    ├── attendance/
    ├── category/
    ├── dashboard/
    ├── inventory/
    ├── licensing/
    ├── products/
    ├── reports/
    ├── sales/
    ├── settings/
    ├── staff/
    ├── stocks/
    ├── suppliers/
    └── users/
```

The intended architecture keeps business logic, database access, UI and external services separated so that individual parts can evolve without rewriting the entire application.

---

# Developer Setup

## Requirements

To develop Creator Yard locally, install:

* Flutter SDK
* Dart SDK compatible with the project
* Git
* Android SDK for Android development
* Xcode for macOS/iOS development
* Android Studio or another Flutter-compatible development environment

For desktop development, use the Flutter platform supported by your operating system.

Check your environment with:

```bash
flutter doctor
```

---

# Clone the Repository

```bash
git clone https://github.com/iamAswift/creator-yard-inventory.git
cd creator-yard-inventory
```

Then install dependencies:

```bash
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

---

# Running the Demo

Creator Yard includes a demo licensing mode for development and evaluation.

The normal development build uses the demo licensing provider unless the commercial build flag is explicitly enabled.

Start the application on macOS:

```bash
flutter run -d macos
```

List available devices:

```bash
flutter devices
```

Run on a specific device:

```bash
flutter run -d <DEVICE_ID>
```

For example:

```bash
flutter run -d macos
```

or:

```bash
flutter run -d <ANDROID_DEVICE_ID>
```

The demo allows developers to inspect the application and work with the local database without requiring production licensing infrastructure.

---

# Running on Android

Connect an Android device with USB debugging enabled or use Android wireless debugging.

Check the available devices:

```bash
adb devices
```

Then:

```bash
flutter devices
```

Run Creator Yard:

```bash
flutter run -d <DEVICE_ID>
```

For Android development, do not clear the application's data while testing unless you intentionally want to create a fresh installation.

The local database contains application data such as users, products, sales and inventory.

---

# Installing on Android POS Devices

Creator Yard is designed to support Android tablets and POS hardware in addition to conventional phones.

A developer can build an APK with:

```bash
flutter build apk
```

The resulting APK can be installed on a compatible Android device using:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

For development builds, use:

```bash
flutter build apk --debug
```

Developers integrating Creator Yard with dedicated POS hardware should test:

* Screen resolution
* Landscape/portrait behavior
* Touch interaction
* Receipt printing
* Barcode scanners
* POS payment hardware
* Device storage
* Application startup
* Local database persistence

Hardware-specific integrations should be implemented without breaking the core offline application.

---

# macOS Development

For macOS development:

```bash
flutter run -d macos
```

To build a macOS application:

```bash
flutter build macos
```

Developers distributing macOS builds should separately handle application signing, notarization and distribution requirements.

Production signing credentials must never be committed to this repository.

---

# iOS Development

iOS development requires macOS and Xcode.

Run:

```bash
flutter devices
```

Then:

```bash
flutter run -d <IOS_DEVICE_ID>
```

Production distribution requires the appropriate Apple signing and provisioning configuration.

Signing credentials and certificates must remain outside the public repository.

---

## Community & Discussions

Creator Yard is intended to be developed with a community of developers, contributors, and implementation partners.

If you are working with the project and want to ask a question, discuss an idea, explore an architectural decision, or share an improvement, use **GitHub Discussions**.

### 💬 GitHub Discussions

Use Discussions for:

* Development questions
* Architecture and database discussions
* Feature ideas
* Android and POS hardware experiences
* Integration discussions
* General project conversations
* Contribution and collaboration topics

**Start or join a discussion:**
https://github.com/iamAswift/creator-yard-inventory/discussions

### 🐛 When to use Issues

Use **GitHub Issues** when a discussion has become a concrete development task, such as:

* A confirmed bug
* A specific implementation task
* A reproducible problem
* A clearly defined improvement
* A documentation task

A feature idea does not need to become an Issue immediately. Discuss the idea first, establish the requirements and approach, and then create an Issue when the work is ready to be planned.

### 🔀 Discussions → Issues → Pull Requests

The intended development flow is:

```text
Discussion
   ↓
Idea / Question / Technical Conversation
   ↓
Defined requirement or confirmed problem
   ↓
GitHub Issue
   ↓
Implementation
   ↓
Pull Request
   ↓
Review
   ↓
Merge
```

This keeps community conversations open while keeping actionable development work organized.

### 🤝 Community participation

Everyone participating in the Creator Yard community is expected to communicate respectfully, provide useful technical information, and help maintain a constructive development environment.

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.


# Local Database

Creator Yard uses Drift over SQLite for its local operational database.

The database contains application data including:

* Users
* User profiles
* Products
* Categories
* Sales
* Stock movements
* Attendance
* Suppliers
* Supplier deliveries
* Supplier payments
* Supplier payment allocations
* Staff purchases
* Staff debt payments
* Application settings
* Email queues

Database access is organized through DAOs.

Generated Drift files should be regenerated using the project's configured build tooling when database definitions change.

Typical command:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Before committing database changes, verify:

```bash
flutter analyze
```

and test the affected feature against an existing database.

---

# Installation Identity

Each Creator Yard installation has a locally generated installation ID.

The ID is stored in the application's existing Settings database and is intended to remain stable for that installation.

It is used by external services that need to identify a particular Creator Yard installation.

The application does not require developers to manually enter an installation ID during normal setup.

---

# Email Credits

Creator Yard includes an optional transactional email system.

Email can be used for functions such as sending sales receipts and future automated reports.

The application does **not** require developers or customers to embed the global Worker API token inside the application.

Instead, the installation registration process creates an installation-specific credential.

The simplified flow is:

```text
Creator Yard installation
        │
        ▼
Generate installation ID
        │
        ▼
Register installation
        │
        ▼
Creator Yard Email API
        │
        ▼
Installation-specific credential
        │
        ▼
Credential stored locally
        │
        ▼
Email Credits requests
        │
        ▼
Creator Yard Email API
```

The credential is stored in the installation's local settings.

Email Credits can be viewed from:

```text
Settings
   → Email Credits
```

The Email Credits area currently supports:

* Credit balance
* Credit history
* Credit purchases
* Transactional email enable/disable
* Low-credit warnings
* Configurable warning thresholds

One email currently consumes one email credit.

The public application repository does not contain production email credentials.

---

# External Services

The core POS system remains local.

External services are isolated to functionality that requires them.

Current external-service areas include:

### Creator Yard Email API

Handles transactional email and email-credit operations.

### Creator Yard Licensing

Handles commercial installation licensing.

### Flutterwave

Used for supported online payment flows such as Email Credit purchases.

### Resend

Used by the email infrastructure for email delivery.

Production credentials, Worker secrets, payment credentials and database credentials must remain outside the public repository.

---

# Licensing

Creator Yard supports a development/demo licensing mode and a commercial licensing architecture.

The application can identify an installation and communicate with the licensing infrastructure when running as a commercial build.

Developers working on the public repository should normally use the demo configuration.

Commercial deployment and activation infrastructure is maintained separately.

Do not attempt to commit production license credentials or infrastructure secrets.

---

# Developer Workflow

The project is intended to support an incremental development workflow.

Before making changes:

```bash
git status
```

After making changes:

```bash
flutter analyze
```

For database changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Then test the affected feature on the appropriate target device.

A recommended workflow is:

```text
Understand
    ↓
Inspect existing implementation
    ↓
Make the smallest required change
    ↓
Format
    ↓
Analyze
    ↓
Run on target device
    ↓
Test existing data
    ↓
Commit
    ↓
Open pull request
```

Avoid broad rewrites when a targeted change is sufficient.

---

# Data Preservation

Creator Yard is an operational retail system.

Application data should be treated as valuable business data.

Developers must **not** use the following as routine debugging steps:

```bash
flutter clean
```

followed by assumptions that the database will be recreated safely.

More importantly, never recommend:

```bash
adb uninstall com.creatoryard.inventory
```

or clearing application storage when investigating normal application behavior unless the test specifically requires a fresh installation.

Future versions of Creator Yard will provide a formal backup and restore system.

---

# Roadmap

The roadmap is intentionally separate from the currently implemented feature set.

Developers should treat the following as planned work rather than completed functionality.

## Phase 1 — Operational Reliability

### Daily Database Backup

Build a reliable backup system that can:

* Create scheduled database backups
* Protect against device failure
* Preserve historical business data
* Allow controlled restore
* Provide backup status
* Detect failed backups
* Keep multiple backup versions

The backup system should work with the offline-first architecture rather than replacing it.

---

## Phase 2 — Automated Business Reports

Build automated reporting that can generate scheduled reports such as:

* Daily sales
* Revenue
* Profit
* Inventory value
* Stock movement
* Low stock
* Supplier balances
* Staff activity
* Reconciliation

Reports should be generated from the local business database.

---

## Phase 3 — Report Delivery Through Email Credits

Use the existing Creator Yard Email Credits infrastructure to allow business owners to receive scheduled reports.

Example:

```text
Store closes
      ↓
Daily report generated
      ↓
Report saved locally
      ↓
Report sent through Email Credits
      ↓
Owner receives report
      ↓
Report retained for future reference
```

The system should not make email delivery a requirement for completing normal sales.

---

## Phase 4 — Local Report Retention

Reports should be retained locally so that the business owner can access historical reports even when the internet is unavailable.

Potential future functionality:

* Report archive
* PDF reports
* CSV exports
* Search by date
* Search by report type
* Local report storage
* Report deletion policies
* Restore from backup

---

## Phase 5 — Device Synchronization

A major future milestone is controlled synchronization between store devices.

For example:

```text
Store Database
      │
      ├── POS Device
      ├── Manager Tablet
      └── Office Computer
             │
             ▼
       Sync Infrastructure
             │
             ▼
      Authorized Devices
```

The synchronization architecture must preserve the offline-first model.

A device should be able to continue operating locally when disconnected and synchronize when connectivity becomes available.

This requires careful design around:

* Conflict resolution
* Transaction ordering
* Device identity
* Data ownership
* Backup recovery
* Duplicate records
* Security
* Offline queues
* Sync status

---

# Future Developer Opportunities

Creator Yard is intentionally being developed so that independent developers and technology partners can contribute to different areas of the system.

Potential areas include:

* Database backup
* Restore systems
* Cloud synchronization
* Report generation
* Automated reporting
* PDF improvements
* Receipt printing integrations
* Barcode hardware
* POS hardware integrations
* Payment integrations
* Inventory intelligence
* Business analytics
* Multi-device synchronization
* Security improvements
* Performance optimization
* UI/UX improvements
* Testing infrastructure
* Automated deployment
* Documentation
* Localization
* Additional retail workflows

The roadmap will evolve as these areas are designed and implemented.

---

# Contributing

Before opening a pull request:

1. Understand the existing implementation.
2. Avoid unnecessary architectural changes.
3. Preserve existing database data and migrations.
4. Keep external credentials out of source control.
5. Format changed Dart files.
6. Run static analysis.
7. Test the affected functionality.
8. Document significant architectural changes.

Example:

```bash
dart format lib
flutter analyze
```

For database changes:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

Pull requests should explain:

* What changed
* Why it changed
* What was tested
* Any migration considerations
* Any future work created by the change

---

# Commercial & Implementation Opportunities

Creator Yard is not only a software development project.

The project is being developed as a commercial retail platform that can be:

* Implemented for retail businesses
* Customized for specific business workflows
* Deployed on computers
* Deployed on tablets
* Deployed on Android POS hardware
* Extended by developers
* Integrated with business services
* Supported by implementation partners

Developers and technology partners may build services, integrations and improvements around the platform.

Commercial deployment should follow the project's licensing and distribution requirements.

If you are interested in becoming a developer, implementation partner or reseller, contact the project owner.

---

# Repository Structure

The Creator Yard ecosystem is being developed as multiple repositories.

```text
Creator Yard
│
├── creator-yard-inventory
│   └── Public Flutter POS & Inventory application
│
├── creator-yard-admin
│   └── Private administration dashboard
│
└── creator-yard-email-api
    └── Private transactional email and Email Credits infrastructure
```

The public inventory repository is intentionally separated from private production infrastructure.

Private repositories contain infrastructure and operational components that should not be exposed with the public application source.

---

# Security

Never commit:

* API tokens
* API keys
* Passwords
* Database credentials
* Cloudflare secrets
* Resend credentials
* Flutterwave secrets
* Apple signing certificates
* Android signing keys
* Production databases
* Customer data
* Private deployment configuration

Use environment variables, local configuration and secure deployment secrets for private infrastructure.

If a secret is accidentally committed, rotate it immediately.

---

# Project Status

Creator Yard is an actively developed commercial product.

The current repository contains a functional POS and inventory system with:

* Local SQLite persistence
* Product management
* Inventory management
* Sales
* Payments
* Suppliers
* Staff
* Attendance
* Reports
* Receipts
* Business settings
* Email Credits
* Installation identity
* Demo licensing
* Commercial licensing architecture
* Responsive desktop, tablet and POS interfaces

The roadmap contains additional infrastructure and synchronization capabilities that are still being designed and developed.

---

# License

Creator Yard is a commercial software project.

The availability of source code on GitHub does not automatically grant unrestricted rights to:

* Resell the software
* Rebrand the software
* Operate commercial deployments
* Redistribute modified builds
* Remove Creator Yard licensing
* Use private infrastructure
* Use production credentials
* Claim ownership of the Creator Yard platform

Specific commercial, reseller, implementation and distribution rights are subject to the project's licensing terms.

---

# Creator Yard

**Build locally. Operate offline. Extend commercially.**

Creator Yard is being built as a retail platform that developers can improve, businesses can deploy and implementation partners can help bring to more stores.
