enum TableStatus {
  available,
  occupied,
  ordering,
  payment,
  paid,
  reserved;

  String get label {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.ordering:
        return 'Ordering';
      case TableStatus.payment:
        return 'Payment';
      case TableStatus.paid:
        return 'Paid';
      case TableStatus.reserved:
        return 'Reserved';
    }
  }

  static TableStatus fromString(String value) {
    switch (value) {
      case 'available':
        return TableStatus.available;
      case 'occupied':
        return TableStatus.occupied;
      case 'ordering':
        return TableStatus.ordering;
      case 'payment':
        return TableStatus.payment;
      case 'paid':
        return TableStatus.paid;
      case 'reserved':
        return TableStatus.reserved;
      default:
        return TableStatus.available;
    }
  }
}

enum OrderStatus {
  new_, processing, preparing, cooking, ready, served, completed, cancelled, paid, merged;

  String get label {
    switch (this) {
      case OrderStatus.new_:
        return 'New';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.cooking:
        return 'Cooking';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.served:
        return 'Served';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.merged:
        return 'Merged';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'new':
        return OrderStatus.new_;
      case 'processing':
        return OrderStatus.processing;
      case 'preparing':
        return OrderStatus.preparing;
      case 'cooking':
        return OrderStatus.cooking;
      case 'ready':
        return OrderStatus.ready;
      case 'served':
        return OrderStatus.served;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'paid':
        return OrderStatus.paid;
      case 'merged':
        return OrderStatus.merged;
      default:
        return OrderStatus.new_;
    }
  }
}

enum ItemStatus {
  pending, accepted, started, cooking, ready, served, completed;

  String get label {
    switch (this) {
      case ItemStatus.pending:
        return 'Pending';
      case ItemStatus.accepted:
        return 'Accepted';
      case ItemStatus.started:
        return 'Started';
      case ItemStatus.cooking:
        return 'Cooking';
      case ItemStatus.ready:
        return 'Ready';
      case ItemStatus.served:
        return 'Served';
      case ItemStatus.completed:
        return 'Completed';
    }
  }

  static ItemStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return ItemStatus.pending;
      case 'accepted':
        return ItemStatus.accepted;
      case 'started':
        return ItemStatus.started;
      case 'cooking':
        return ItemStatus.cooking;
      case 'ready':
        return ItemStatus.ready;
      case 'served':
        return ItemStatus.served;
      case 'completed':
        return ItemStatus.completed;
      default:
        return ItemStatus.pending;
    }
  }
}

enum PaymentStatus {
  unpaid, pendingPayment, paid;

  String get label {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.pendingPayment:
        return 'Payment Requested';
      case PaymentStatus.paid:
        return 'Paid';
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value) {
      case 'unpaid':
        return PaymentStatus.unpaid;
      case 'pending_payment':
        return PaymentStatus.pendingPayment;
      case 'paid':
        return PaymentStatus.paid;
      default:
        return PaymentStatus.unpaid;
    }
  }
}
