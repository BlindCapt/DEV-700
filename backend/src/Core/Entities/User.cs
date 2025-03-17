namespace Core.Entities
{
    public class User
    {
        public int Id { get; set; }
        public string Username { get; set; }
        public string Password { get; set; }  // Sera hashé
        public string Role { get; set; }  // "MANAGER" ou "EMPLOYEE"
    }
}
