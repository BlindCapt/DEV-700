using Microsoft.EntityFrameworkCore;
using Core.Entities;
using BCrypt.Net;
using System;

namespace Infrastructure.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Product> Products { get; set; }
        public DbSet<WebUser> WebUsers { get; set; }
        public DbSet<MobileUser> MobileUsers { get; set; }
        public DbSet<Cart> Carts { get; set; }
        public DbSet<CartItem> CartItems { get; set; }
        public DbSet<Favorite> Favorites { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Configuration des relations
            modelBuilder.Entity<Cart>()
                .HasOne(c => c.MobileUser)
                .WithMany(u => u.Carts)
                .HasForeignKey(c => c.MobileUserId);

            modelBuilder.Entity<CartItem>()
                .HasOne(ci => ci.Cart)
                .WithMany(c => c.Items)
                .HasForeignKey(ci => ci.CartId);

            modelBuilder.Entity<CartItem>()
                .HasOne(ci => ci.Product)
                .WithMany()
                .HasForeignKey(ci => ci.ProductId);
                
            // Configuration des relations pour les favoris
            modelBuilder.Entity<Favorite>()
                .HasOne(f => f.MobileUser)
                .WithMany(u => u.Favorites)
                .HasForeignKey(f => f.MobileUserId);
                
            modelBuilder.Entity<Favorite>()
                .HasOne(f => f.Product)
                .WithMany()
                .HasForeignKey(f => f.ProductId);
                
            // Index unique pour éviter les doublons de favoris (un utilisateur ne peut mettre un produit en favori qu'une seule fois)
            modelBuilder.Entity<Favorite>()
                .HasIndex(f => new { f.MobileUserId, f.ProductId })
                .IsUnique();

            // Seed du WebUser admin avec un hash pré-calculé statique
            // Hash validé et testé pour le mot de passe "admin"
            const string staticHashedPassword = "$2a$11$kkhBm1nsqPJT7MffhvW/A..3QF6yjgI076.F39NoPED4xwGWlIyyO";
            
            modelBuilder.Entity<WebUser>().HasData(
                new WebUser 
                { 
                    Id = 1, 
                    Username = "admin",
                    Password = staticHashedPassword,
                    Email = "admin@example.com",
                    FirstName = "Admin",
                    LastName = "User",
                    Role = WebUserRole.Manager,
                    CreatedAt = new DateTime(2023, 1, 1, 0, 0, 0, DateTimeKind.Utc)  // Date statique
                }
            );
        }
    }
}
