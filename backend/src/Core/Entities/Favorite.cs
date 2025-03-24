namespace Core.Entities
{
    public class Favorite
    {
        public int Id { get; set; }
        public int MobileUserId { get; set; }
        public int ProductId { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Relations
        public MobileUser MobileUser { get; set; }
        public Product Product { get; set; }
    }
} 