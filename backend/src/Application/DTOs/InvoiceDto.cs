using System;
using System.Collections.Generic;
using Core.Entities;

namespace Application.DTOs
{
    public class InvoiceDto
    {
        public int Id { get; set; }
        public string InvoiceNumber { get; set; }
        public int MobileUserId { get; set; }
        public string MobileUserName { get; set; } // Prénom + Nom de l'utilisateur mobile
        public int CartId { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? PaidAt { get; set; }
        public decimal TotalAmount { get; set; }
        public string Status { get; set; } // Convertie en chaîne pour l'API
        public string? PaymentMethod { get; set; }
        public string? PaymentReference { get; set; }
        public string? BillingAddress { get; set; }
        public string? Notes { get; set; }
        
        // Propriétés pour inclure les détails du panier
        public CartDto? Cart { get; set; }
    }

    public class CartDto
    {
        public int Id { get; set; }
        public List<CartItemDto> CartItems { get; set; } = new List<CartItemDto>();
    }

    public class CartItemDto
    {
        public int Id { get; set; }
        public int Quantity { get; set; }
        public ProductDto Product { get; set; }
    }

    public class ProductDto
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Brand { get; set; }
        public string Category { get; set; }
        public decimal Price { get; set; }
        public string ImageUrl { get; set; }
    }

    public class CreateInvoiceDto
    {
        public int CartId { get; set; }
        public string? BillingAddress { get; set; }
        public string? Notes { get; set; }
    }

    public class UpdateInvoiceDto
    {
        public string? BillingAddress { get; set; }
        public string? Notes { get; set; }
        public string? PaymentMethod { get; set; }
        public string? PaymentReference { get; set; }
        public InvoiceStatus Status { get; set; }
    }

    public class PayInvoiceDto
    {
        public string PaymentMethod { get; set; }
        public string PaymentReference { get; set; }
    }
} 