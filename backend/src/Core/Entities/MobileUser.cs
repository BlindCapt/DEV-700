namespace Core.Entities
{
    public class MobileUser
    {
        public int Id { get; set; }
        public string Email { get; set; }
        public string Password { get; set; }  // Sera hashé
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string PhoneNumber { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? LastLogin { get; set; }
        public bool IsActive { get; set; } = true;
        
        // Relations
        public List<Cart> Carts { get; set; } = new List<Cart>();
        public List<Favorite> Favorites { get; set; } = new List<Favorite>();
    }
} 