using Microsoft.EntityFrameworkCore;
using Core.Entities;

namespace Infrastructure.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Product> Products { get; set; } = null!;  // Ajout de null! pour satisfaire la nullabilité
        public DbSet<User> Users { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Configuration des propriétés
            modelBuilder.Entity<Product>()
                .Property(p => p.Price)
                .HasColumnType("decimal(18,2)");

            // Seed initial manager user
            modelBuilder.Entity<User>().HasData(
                new User 
                { 
                    Id = 1, 
                    Username = "admin",
                    Password = "$2a$11$7IoY8/YB.7zj2tYS3UHaKOiAI0V71vNhQ1P.Lu9TJAQoqgEDxULuy",
                    Role = "MANAGER"
                }
            );
        }
    }
}
