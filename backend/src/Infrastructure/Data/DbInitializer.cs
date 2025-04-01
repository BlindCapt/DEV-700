using Core.Entities;
using Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

namespace Infrastructure.Data
{
    public static class DbInitializer
    {
        public static void Initialize(IServiceProvider serviceProvider)
        {
            using var scope = serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            var logger = scope.ServiceProvider.GetRequiredService<ILogger<AppDbContext>>();

            try
            {
                context.Database.EnsureCreated();

                // Seed uniquement si aucune donnée n'existe
                if (!context.MobileUsers.Any() && !context.Products.Any() && !context.Invoices.Any())
                {
                    logger.LogInformation("Début de l'initialisation de la base de données avec des données de test.");
                    
                    // 1. Ajouter des utilisateurs mobiles
                    SeedMobileUsers(context);
                    
                    // 2. Ajouter des produits
                    SeedProducts(context);
                    
                    // 3. Ajouter des paniers et des éléments de panier
                    SeedCarts(context);
                    
                    // 4. Ajouter des factures
                    SeedInvoices(context);
                    
                    logger.LogInformation("Initialisation de la base de données terminée avec succès.");
                }
                else
                {
                    logger.LogInformation("La base de données contient déjà des données, initialisation ignorée.");
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Une erreur s'est produite lors de l'initialisation de la base de données.");
                throw;
            }
        }

        private static void SeedMobileUsers(AppDbContext context)
        {
            var users = new List<MobileUser>
            {
                new MobileUser
                {
                    Email = "client1@example.com",
                    Password = HashPassword("Password123!"), // Hachage du mot de passe
                    FirstName = "Jean",
                    LastName = "Dupont",
                    PhoneNumber = "0612345678",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddMonths(-2)
                },
                new MobileUser
                {
                    Email = "client2@example.com",
                    Password = HashPassword("Password123!"),
                    FirstName = "Marie",
                    LastName = "Martin",
                    PhoneNumber = "0698765432",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddMonths(-1)
                },
                new MobileUser
                {
                    Email = "client3@example.com",
                    Password = HashPassword("Password123!"),
                    FirstName = "Pierre",
                    LastName = "Bernard",
                    PhoneNumber = "0678901234",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow.AddDays(-15)
                },
                new MobileUser
                {
                    Email = "client4@example.com",
                    Password = HashPassword("Password123!"),
                    FirstName = "Sophie",
                    LastName = "Dubois",
                    PhoneNumber = "0645678901",
                    IsActive = false, // Utilisateur inactif pour tester ce cas
                    CreatedAt = DateTime.UtcNow.AddDays(-20)
                }
            };

            context.MobileUsers.AddRange(users);
            context.SaveChanges();
        }

        private static void SeedProducts(AppDbContext context)
        {
            var products = new List<Product>
            {
                new Product
                {
                    Name = "Smartphone Galaxy S22",
                    Brand = "Samsung",
                    Category = "Électronique",
                    Price = 899.99m,
                    Quantity = 50,
                    Threshold = 10,
                    Barcode = "1234567890123",
                    ImageUrl = "https://example.com/images/galaxy-s22.jpg"
                },
                new Product
                {
                    Name = "iPhone 14 Pro",
                    Brand = "Apple",
                    Category = "Électronique",
                    Price = 1159.99m,
                    Quantity = 30,
                    Threshold = 5,
                    Barcode = "2345678901234",
                    ImageUrl = "https://example.com/images/iphone-14-pro.jpg"
                },
                new Product
                {
                    Name = "Laptop XPS 15",
                    Brand = "Dell",
                    Category = "Informatique",
                    Price = 1599.99m,
                    Quantity = 20,
                    Threshold = 3,
                    Barcode = "3456789012345",
                    ImageUrl = "https://example.com/images/xps-15.jpg"
                },
                new Product
                {
                    Name = "Écouteurs WH-1000XM5",
                    Brand = "Sony",
                    Category = "Audio",
                    Price = 399.99m,
                    Quantity = 40,
                    Threshold = 8,
                    Barcode = "4567890123456",
                    ImageUrl = "https://example.com/images/wh-1000xm5.jpg"
                },
                new Product
                {
                    Name = "Tablette iPad Air",
                    Brand = "Apple",
                    Category = "Électronique",
                    Price = 699.99m,
                    Quantity = 25,
                    Threshold = 5,
                    Barcode = "5678901234567",
                    ImageUrl = "https://example.com/images/ipad-air.jpg"
                },
                new Product
                {
                    Name = "Montre connectée Watch 5",
                    Brand = "Samsung",
                    Category = "Accessoires",
                    Price = 329.99m,
                    Quantity = 35,
                    Threshold = 7,
                    Barcode = "6789012345678",
                    ImageUrl = "https://example.com/images/galaxy-watch5.jpg"
                },
                new Product
                {
                    Name = "TV OLED 55 pouces",
                    Brand = "LG",
                    Category = "Électronique",
                    Price = 1299.99m,
                    Quantity = 15,
                    Threshold = 3,
                    Barcode = "7890123456789",
                    ImageUrl = "https://example.com/images/lg-oled55.jpg"
                }
            };

            context.Products.AddRange(products);
            context.SaveChanges();
        }

        private static void SeedCarts(AppDbContext context)
        {
            var users = context.MobileUsers.ToList();
            var products = context.Products.ToList();
            
            var carts = new List<Cart>();
            
            // Cart 1 - Terminé, pour la facture en attente
            var cart1 = new Cart
            {
                MobileUserId = users[0].Id,
                IsActive = false,
                CreatedAt = DateTime.UtcNow.AddDays(-5),
                CompletedAt = DateTime.UtcNow.AddDays(-5)
            };
            carts.Add(cart1);
            
            // Cart 2 - Terminé, pour la facture payée
            var cart2 = new Cart
            {
                MobileUserId = users[1].Id,
                IsActive = false,
                CreatedAt = DateTime.UtcNow.AddDays(-15),
                CompletedAt = DateTime.UtcNow.AddDays(-15)
            };
            carts.Add(cart2);
            
            // Cart 3 - Terminé, pour la facture annulée
            var cart3 = new Cart
            {
                MobileUserId = users[2].Id,
                IsActive = false,
                CreatedAt = DateTime.UtcNow.AddDays(-10),
                CompletedAt = DateTime.UtcNow.AddDays(-10)
            };
            carts.Add(cart3);
            
            // Cart 4 - Actif, en cours d'utilisation
            var cart4 = new Cart
            {
                MobileUserId = users[0].Id,
                IsActive = true,
                CreatedAt = DateTime.UtcNow.AddHours(-2)
            };
            carts.Add(cart4);
            
            context.Carts.AddRange(carts);
            context.SaveChanges();
            
            // Ajouter des éléments aux paniers
            var cartItems = new List<CartItem>();
            
            // Items pour le panier 1 (facture en attente)
            cartItems.Add(new CartItem
            {
                CartId = cart1.Id,
                ProductId = products[0].Id,
                Quantity = 1
            });
            cartItems.Add(new CartItem
            {
                CartId = cart1.Id,
                ProductId = products[3].Id,
                Quantity = 1
            });
            
            // Items pour le panier 2 (facture payée)
            cartItems.Add(new CartItem
            {
                CartId = cart2.Id,
                ProductId = products[1].Id,
                Quantity = 1
            });
            cartItems.Add(new CartItem
            {
                CartId = cart2.Id,
                ProductId = products[5].Id,
                Quantity = 2
            });
            
            // Items pour le panier 3 (facture annulée)
            cartItems.Add(new CartItem
            {
                CartId = cart3.Id,
                ProductId = products[2].Id,
                Quantity = 1
            });
            
            // Items pour le panier actif
            cartItems.Add(new CartItem
            {
                CartId = cart4.Id,
                ProductId = products[4].Id,
                Quantity = 1
            });
            
            context.CartItems.AddRange(cartItems);
            context.SaveChanges();
        }

        private static void SeedInvoices(AppDbContext context)
        {
            var carts = context.Carts.Include(c => c.Items).ThenInclude(i => i.Product).Where(c => !c.IsActive).ToList();
            
            var invoices = new List<Invoice>();
            
            // Facture 1 - En attente
            var pendingInvoice = new Invoice
            {
                InvoiceNumber = "INV-202405-0001",
                MobileUserId = carts[0].MobileUserId,
                CartId = carts[0].Id,
                TotalAmount = carts[0].Items.Sum(i => i.Quantity * i.Product.Price),
                Status = InvoiceStatus.Pending,
                CreatedAt = DateTime.UtcNow.AddDays(-5),
                BillingAddress = "123 Rue de Paris, 75001 Paris, France",
                Notes = "Livraison standard"
            };
            invoices.Add(pendingInvoice);
            
            // Facture 2 - Payée
            var paidInvoice = new Invoice
            {
                InvoiceNumber = "INV-202405-0002",
                MobileUserId = carts[1].MobileUserId,
                CartId = carts[1].Id,
                TotalAmount = carts[1].Items.Sum(i => i.Quantity * i.Product.Price),
                Status = InvoiceStatus.Paid,
                CreatedAt = DateTime.UtcNow.AddDays(-15),
                PaidAt = DateTime.UtcNow.AddDays(-14),
                PaymentMethod = "CreditCard",
                PaymentReference = "TXN-123456789",
                BillingAddress = "456 Boulevard Haussmann, 75008 Paris, France",
                Notes = "Livraison express"
            };
            invoices.Add(paidInvoice);
            
            // Facture 3 - Annulée
            var cancelledInvoice = new Invoice
            {
                InvoiceNumber = "INV-202405-0003",
                MobileUserId = carts[2].MobileUserId,
                CartId = carts[2].Id,
                TotalAmount = carts[2].Items.Sum(i => i.Quantity * i.Product.Price),
                Status = InvoiceStatus.Cancelled,
                CreatedAt = DateTime.UtcNow.AddDays(-10),
                BillingAddress = "789 Avenue des Champs-Élysées, 75016 Paris, France",
                Notes = "Client a demandé l'annulation"
            };
            invoices.Add(cancelledInvoice);
            
            context.Invoices.AddRange(invoices);
            context.SaveChanges();
        }

        // Méthode pour hacher les mots de passe (implémenter selon votre méthode de hashage)
        private static string HashPassword(string password)
        {
            // Exemple simple de hachage avec SHA256 - à adapter selon votre implémentation réelle
            using var sha256 = SHA256.Create();
            var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(hashedBytes);
        }
    }
}
