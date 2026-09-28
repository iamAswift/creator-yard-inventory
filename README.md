# Creator Yard

**Offline-first POS and inventory management for retail businesses.**

Creator Yard is a Flutter-based retail platform designed for businesses that need their core operations to keep working when internet connectivity is unreliable.

It runs primarily on the local device using **SQLite + Drift**, while external services are used only where connectivity is required.

Creator Yard is being developed as a **commercial retail platform and an open developer project** for developers, implementation partners and technology partners.

---

## What It Does

### 🛒 POS

- Cash, card/POS and bank-transfer payments
- Split payments and discounts
- Customer information
- Configurable payment methods
- Receipts and printing
- Transactional email receipts

### 📦 Products & Inventory

- Products and categories
- Product images
- Stock management
- Stock movements and adjustments
- Stock receiving
- Low-stock and out-of-stock monitoring
- Inventory valuation
- Product history
- Optional expiry tracking

### 🚚 Suppliers

Supplier Management is optional.

Businesses that use suppliers can manage:

- Suppliers
- Deliveries
- Delivery items
- Supplier payments
- Payment allocation
- Statements
- Supplier credit

Businesses that do not need supplier tracking can disable the feature and enter existing stock directly when creating products.

### 👥 Staff & Users

- User accounts
- Staff management
- Permissions
- Attendance
- Staff purchases
- Staff debt
- Security settings

### 📊 Reports

- Sales
- Revenue and profit
- Items sold
- Categories
- Inventory value
- Low stock
- Out-of-stock products
- Expiry reports
- Staff activity
- Reconciliation
- Exports

---

## Offline-First

Core retail operations are stored locally.

```text
                  Creator Yard
                       │
             ┌─────────┴─────────┐
             │                   │
       Local Database      External Services
             │                   │
        SQLite + Drift    Email / Licensing
             │             Payments / Future Sync
             │
      POS · Products · Stock · Staff
