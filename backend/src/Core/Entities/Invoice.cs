using System;
using System.Collections.Generic;

namespace Core.Entities
{
    public class Invoice
    {
        public int Id { get; set; }
        public string InvoiceNumber { get; set; }
        public int MobileUserId { get; set; }
        public MobileUser MobileUser { get; set; }
        public int CartId { get; set; }
        public Cart Cart { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? PaidAt { get; set; }
        public decimal TotalAmount { get; set; }
        public InvoiceStatus Status { get; set; } = InvoiceStatus.Pending;
        public string? PaymentMethod { get; set; }
        public string? PaymentReference { get; set; }
        public string? BillingAddress { get; set; }
        public string? Notes { get; set; }
    }

    public enum InvoiceStatus
    {
        Pending,
        Paid,
        Cancelled,
        Refunded
    }
} 