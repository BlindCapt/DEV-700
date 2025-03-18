using System;

namespace Domain.Entities
{
    public class CartItem
    {
        public int Id { get; set; }
        public int CartId { get; set; }
        public int ProductId { get; set; }
        public int Quantity { get; set; }
        public DateTime AddedAt { get; set; }
        
        // Relations avec les autres entités
        public virtual Cart Cart { get; set; }
        public virtual Product Product { get; set; }
    }
} 