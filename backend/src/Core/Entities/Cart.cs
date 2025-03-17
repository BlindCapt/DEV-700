namespace Core.Entities
{
    public class Cart
    {
        public int Id { get; set; }
        public int MobileUserId { get; set; }
        public MobileUser MobileUser { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? CompletedAt { get; set; }
        public bool IsActive { get; set; } = true;
        
        // Relations
        public List<CartItem> Items { get; set; } = new List<CartItem>();
    }
} 