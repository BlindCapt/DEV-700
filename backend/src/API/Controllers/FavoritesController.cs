using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Core.Entities;
using System.Security.Claims;
using static API.Controllers.CartsController; // Import des DTOs du CartsController

namespace API.Controllers
{
    [ApiController]
    [Route("api/favorites")]
    [Authorize]
    public class FavoritesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public FavoritesController(AppDbContext context)
        {
            _context = context;
        }

        // Obtenir tous les favoris de l'utilisateur connecté
        [HttpGet]
        public async Task<ActionResult<List<FavoriteDto>>> GetUserFavorites()
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized("Utilisateur non authentifié");
                }

                var favorites = await _context.Favorites
                    .Include(f => f.Product)
                    .Where(f => f.MobileUserId == int.Parse(userId))
                    .Select(f => new FavoriteDto
                    {
                        Id = f.Id,
                        ProductId = f.ProductId,
                        CreatedAt = f.CreatedAt,
                        Product = new ProductDto
                        {
                            Id = f.Product.Id,
                            Barcode = f.Product.Barcode,
                            Name = f.Product.Name,
                            Brand = f.Product.Brand,
                            Category = f.Product.Category,
                            ImageUrl = f.Product.ImageUrl,
                            Price = f.Product.Price,
                            Quantity = f.Product.Quantity,
                            Threshold = f.Product.Threshold
                        }
                    })
                    .ToListAsync();

                return Ok(favorites);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Erreur lors de la récupération des favoris: {ex.Message}");
            }
        }

        // Vérifier si un produit est dans les favoris
        [HttpGet("check/{productId}")]
        public async Task<ActionResult<bool>> CheckFavorite(int productId)
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized("Utilisateur non authentifié");
                }

                var isFavorite = await _context.Favorites
                    .AnyAsync(f => f.MobileUserId == int.Parse(userId) && f.ProductId == productId);

                return Ok(isFavorite);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Erreur lors de la vérification du favori: {ex.Message}");
            }
        }

        // Ajouter un produit aux favoris
        [HttpPost]
        public async Task<ActionResult> AddToFavorites([FromBody] AddFavoriteDto model)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(ModelState);
                }

                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized("Utilisateur non authentifié");
                }

                // Vérifier si le produit existe
                var product = await _context.Products.FindAsync(model.ProductId);
                if (product == null)
                {
                    return NotFound("Produit non trouvé");
                }

                // Vérifier si le produit est déjà dans les favoris
                var existingFavorite = await _context.Favorites
                    .FirstOrDefaultAsync(f => f.MobileUserId == int.Parse(userId) && f.ProductId == model.ProductId);

                if (existingFavorite != null)
                {
                    return Ok(new { Message = "Ce produit est déjà dans vos favoris" });
                }

                // Ajouter aux favoris
                var favorite = new Favorite
                {
                    MobileUserId = int.Parse(userId),
                    ProductId = model.ProductId,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Favorites.Add(favorite);
                await _context.SaveChangesAsync();

                return Created(string.Empty, new { Message = "Produit ajouté aux favoris" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Erreur lors de l'ajout aux favoris: {ex.Message}");
            }
        }

        // Supprimer un produit des favoris
        [HttpDelete("{productId}")]
        public async Task<ActionResult> RemoveFromFavorites(int productId)
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized("Utilisateur non authentifié");
                }

                // Trouver le favori à supprimer
                var favorite = await _context.Favorites
                    .FirstOrDefaultAsync(f => f.MobileUserId == int.Parse(userId) && f.ProductId == productId);

                if (favorite == null)
                {
                    return NotFound("Ce produit n'est pas dans vos favoris");
                }

                // Supprimer des favoris
                _context.Favorites.Remove(favorite);
                await _context.SaveChangesAsync();

                return Ok(new { Message = "Produit retiré des favoris" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Erreur lors de la suppression du favori: {ex.Message}");
            }
        }
    }

    // DTOs (Data Transfer Objects)
    public class FavoriteDto
    {
        public int Id { get; set; }
        public int ProductId { get; set; }
        public DateTime CreatedAt { get; set; }
        public ProductDto Product { get; set; }
    }

    public class AddFavoriteDto
    {
        public int ProductId { get; set; }
    }
} 