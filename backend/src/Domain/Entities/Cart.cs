using System;
using System.Collections.Generic;

namespace Domain.Entities
{
    public class Cart
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsActive { get; set; } = true;
        
        // Relation avec les articles du panier
        public virtual ICollection<CartItem> CartItems { get; set; } = new List<CartItem>();
    }
} 