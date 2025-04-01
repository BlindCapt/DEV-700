using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Core.Entities;
using Microsoft.AspNetCore.Authorization;
using System;
using System.Linq;
using System.Threading.Tasks;
using System.Collections.Generic;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Hosting;

namespace API.Controllers
{
    [Route("api/kpi")]
    [ApiController]
    public class KPIController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ILogger<KPIController> _logger;
        private readonly IHostEnvironment _environment;

        public KPIController(AppDbContext context, ILogger<KPIController> logger, IHostEnvironment environment)
        {
            _context = context;
            _logger = logger;
            _environment = environment;
        }

        [HttpGet]
        [Authorize(Roles = "Admin,Manager")]
        public async Task<IActionResult> GetDashboardKPIs()
        {
            return await GetKpiData();
        }

        private async Task<IActionResult> GetKpiData()
        {
            try
            {
                _logger.LogInformation("Récupération des données KPI demandée");
                
                // KPI 1: Chiffre d'affaires total - s'assurer que les factures ont bien été payées (PaidAt non null)
                var totalRevenue = await _context.Invoices
                    .Where(i => i.Status == InvoiceStatus.Paid && i.PaidAt.HasValue)
                    .SumAsync(i => i.TotalAmount);
                
                _logger.LogInformation("Chiffre d'affaires total calculé: {TotalRevenue}", totalRevenue);

                // KPI 2: Nombre total de commandes
                var totalOrders = await _context.Invoices.CountAsync();
                _logger.LogInformation("Nombre total de commandes: {TotalOrders}", totalOrders);
                
                // KPI 3: Panier moyen - corrigé pour éviter l'exception en cas de données vides
                double averageOrderValue = 0;
                var paidInvoices = await _context.Invoices
                    .Where(i => i.Status == InvoiceStatus.Paid && i.PaidAt.HasValue)
                    .ToListAsync();
                
                if (paidInvoices.Any())
                {
                    averageOrderValue = paidInvoices.Average(i => (double)i.TotalAmount);
                }
                _logger.LogInformation("Panier moyen: {AverageOrderValue}", averageOrderValue);
                
                // KPI 4: Produits en rupture de stock ou sous le seuil d'alerte
                var lowStockProducts = await _context.Products
                    .Where(p => p.Quantity <= p.Threshold)
                    .CountAsync();
                _logger.LogInformation("Produits en stock faible: {LowStockProducts}", lowStockProducts);
                
                // KPI 5: Nombre d'utilisateurs actifs
                var activeUsers = await _context.MobileUsers
                    .Where(u => u.IsActive)
                    .CountAsync();
                _logger.LogInformation("Utilisateurs actifs: {ActiveUsers}", activeUsers);

                // Données pour les graphiques - ajout de vérifications pour éviter les exceptions
                var revenueByMonth = await GetRevenueByMonth();
                var topSellingProducts = await GetTopSellingProducts(5);
                var ordersByStatus = await GetOrdersByStatus();
                var userGrowth = await GetUserGrowthData();
                var productCategories = await GetProductCategoriesDistribution();

                var result = new
                {
                    kpis = new
                    {
                        totalRevenue,
                        totalOrders,
                        averageOrderValue,
                        lowStockProducts,
                        activeUsers
                    },
                    charts = new
                    {
                        revenueByMonth,
                        topSellingProducts,
                        ordersByStatus,
                        userGrowth,
                        productCategories
                    }
                };

                _logger.LogInformation("Données KPI récupérées avec succès");
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erreur lors de la récupération des KPI");
                // Retourner une erreur 500 avec un message explicite
                return StatusCode(500, new { 
                    error = "Erreur lors de la récupération des KPI", 
                    message = ex.Message,
                    details = $"Une erreur s'est produite lors du traitement des données: {ex.Message}"
                });
            }
        }

        private async Task<List<object>> GetRevenueByMonth()
        {
            _logger.LogInformation("Calcul des revenus par mois");
            // Utiliser 7 mois pour inclure le mois en cours et les 6 précédents
            var startDate = DateTime.UtcNow.AddMonths(-6);
            
            // Utiliser PaidAt au lieu de CreatedAt pour les revenus
            var invoicesByMonth = await _context.Invoices
                .Where(i => i.Status == InvoiceStatus.Paid && i.PaidAt.HasValue && i.PaidAt.Value >= startDate)
                .GroupBy(i => new { Year = i.PaidAt.Value.Year, Month = i.PaidAt.Value.Month })
                .Select(g => new 
                {
                    Year = g.Key.Year,
                    Month = g.Key.Month,
                    Revenue = g.Sum(i => i.TotalAmount)
                })
                .OrderBy(r => r.Year)
                .ThenBy(r => r.Month)
                .ToListAsync();
            
            _logger.LogInformation("Nombre de mois avec des données de revenus: {Count}", invoicesByMonth.Count);
            
            var result = new List<object>();
            
            // S'assurer que tous les mois sont représentés, y compris le mois courant
            for (int i = 0; i <= 6; i++)  // Inclure les 6 derniers mois plus le mois en cours
            {
                var date = startDate.AddMonths(i);
                var year = date.Year;
                var month = date.Month;
                
                var existingData = invoicesByMonth
                    .FirstOrDefault(d => d.Year == year && d.Month == month);
                
                var monthName = System.Globalization.CultureInfo.CurrentCulture
                    .DateTimeFormat.GetMonthName(month);
                
                var revenue = existingData?.Revenue ?? 0;
                
                result.Add(new 
                {
                    month = $"{monthName} {year}",
                    monthShort = $"{monthName.Substring(0, 3)}",
                    revenue
                });
            }
            
            _logger.LogInformation("Données de revenus mensuels préparées: {Count} mois", result.Count);
            
            return result.Cast<object>().ToList();
        }

        private async Task<List<object>> GetTopSellingProducts(int limit)
        {
            _logger.LogInformation("Récupération des produits les plus vendus");
            
            // Récupérer d'abord les ID des paniers qui ont des factures payées
            var paidCartIds = await _context.Invoices
                .Where(i => i.Status == InvoiceStatus.Paid)
                .Select(i => i.CartId)
                .ToListAsync();
            
            _logger.LogInformation("Nombre de paniers avec factures payées: {Count}", paidCartIds.Count);
            
            // Récupérer les articles des paniers payés uniquement
            var topProducts = await _context.CartItems
                .Where(ci => paidCartIds.Contains(ci.CartId))
                .Include(ci => ci.Product)
                .GroupBy(ci => ci.ProductId)
                .Select(g => new 
                {
                    ProductId = g.Key,
                    ProductName = g.First().Product.Name,
                    TotalQuantity = g.Sum(ci => ci.Quantity),
                    TotalRevenue = g.Sum(ci => ci.Price * ci.Quantity)
                })
                .OrderByDescending(p => p.TotalQuantity)
                .Take(limit)
                .ToListAsync();

            _logger.LogInformation("Nombre de produits populaires trouvés: {Count}", topProducts.Count);
            
            return topProducts.Select(p => new 
            {
                product = p.ProductName,
                quantity = p.TotalQuantity,
                revenue = p.TotalRevenue
            }).Cast<object>().ToList();
        }

        private async Task<List<object>> GetOrdersByStatus()
        {
            _logger.LogInformation("Récupération des commandes par statut");
            var ordersByStatus = await _context.Invoices
                .GroupBy(i => i.Status)
                .Select(g => new
                {
                    Status = g.Key,
                    Count = g.Count()
                })
                .ToListAsync();

            _logger.LogInformation("Nombre de statuts différents: {Count}", ordersByStatus.Count);
            
            // S'assurer que tous les statuts sont représentés
            var allStatuses = Enum.GetValues(typeof(InvoiceStatus))
                .Cast<InvoiceStatus>()
                .ToList();

            var result = new List<object>();
            
            foreach (var status in allStatuses)
            {
                var statusData = ordersByStatus.FirstOrDefault(s => s.Status == status);
                var statusName = status.ToString().ToLower();
                
                result.Add(new
                {
                    status = statusName,
                    value = statusData?.Count ?? 0
                });
            }

            return result;
        }

        private async Task<List<object>> GetUserGrowthData()
        {
            _logger.LogInformation("Récupération des données de croissance utilisateurs");
            var startDate = DateTime.UtcNow.AddMonths(-6);
            
            var usersByMonth = await _context.MobileUsers
                .Where(u => u.CreatedAt >= startDate)
                .GroupBy(u => new { u.CreatedAt.Year, u.CreatedAt.Month })
                .Select(g => new
                {
                    Year = g.Key.Year,
                    Month = g.Key.Month,
                    NewUsers = g.Count()
                })
                .OrderBy(r => r.Year)
                .ThenBy(r => r.Month)
                .ToListAsync();

            _logger.LogInformation("Nombre de mois avec croissance utilisateurs: {Count}", usersByMonth.Count);
            
            var result = new List<object>();
            
            // S'assurer que tous les mois sont représentés, y compris le mois courant
            for (int i = 0; i <= 6; i++)
            {
                var date = startDate.AddMonths(i);
                var year = date.Year;
                var month = date.Month;
                
                var existingData = usersByMonth
                    .FirstOrDefault(d => d.Year == year && d.Month == month);
                
                var monthName = System.Globalization.CultureInfo.CurrentCulture
                    .DateTimeFormat.GetMonthName(month);
                
                result.Add(new
                {
                    month = $"{monthName} {year}",
                    monthShort = $"{monthName.Substring(0, 3)}",
                    users = existingData?.NewUsers ?? 0
                });
            }
            
            _logger.LogInformation("Données de croissance utilisateurs préparées: {Count} mois", result.Count);
            
            return result.Cast<object>().ToList();
        }

        private async Task<List<object>> GetProductCategoriesDistribution()
        {
            _logger.LogInformation("Récupération de la distribution des catégories de produits");
            var categories = await _context.Products
                .GroupBy(p => p.Category)
                .Select(g => new
                {
                    Category = g.Key,
                    Count = g.Count()
                })
                .OrderByDescending(c => c.Count)
                .ToListAsync();

            _logger.LogInformation("Nombre de catégories trouvées: {Count}", categories.Count);
            
            return categories.Select(c => new
            {
                category = c.Category,
                value = c.Count
            }).Cast<object>().ToList();
        }
    }
} 