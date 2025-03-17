namespace Core.Entities
{
    public class WebUser
    {
        public int Id { get; set; }
        public string Username { get; set; }
        public string Password { get; set; }  // Sera hashé
        public string Email { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public WebUserRole Role { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? LastLogin { get; set; }
    }

    public enum WebUserRole
    {
        Manager,    // Accès complet (gestion des stocks, des utilisateurs web et mobile)
        Employee    // Accès limité (gestion des stocks uniquement)
    }
} 