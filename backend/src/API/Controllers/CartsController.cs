using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Core.Entities;
using System.Security.Claims;

namespace API.Controllers
{
    [ApiController]
    [Route("api/carts")]
    [Authorize]
    public class CartsController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CartsController(AppDbContext context)
        {
            _context = context;
        }

        // Récupérer le panier actif de l'utilisateur connecté
        [HttpGet("active")]
        public async Task<ActionResult<CartDto>> GetActiveCart()
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized("Utilisateur non authentifié");
                }

                // Récupérer le panier actif avec ses articles et les informations produits
                var cart = await _context.Carts
                    .Include(c => c.Items)
                    .ThenInclude(ci => ci.Product)
                    .FirstOrDefaultAsync(c => c.MobileUserId == int.Parse(userId) && c.IsActive);

                if (cart == null)
                {
                    return NotFound("Aucun panier actif trouvé");
                }

                // Mapper vers DTO
                var cartDto = new CartDto
                {
                    Id = cart.Id,
                    CartItems = cart.Items.Select(ci => new CartItemDto
                    {
                        Id = ci.Id,
                        Quantity = ci.Quantity,
                        Product = new ProductDto
                        {
                            Id = ci.Product.Id,
                            Barcode = ci.Product.Barcode,
                            Name = ci.Product.Name,
                            Brand = ci.Product.Brand,
                            Category = ci.Product.Category,
                            ImageUrl = ci.Product.ImageUrl,
                            Price = ci.Product.Price,
                            Quantity = ci.Product.Quantity,
                            Threshold = ci.Product.Threshold
                        }
                    }).ToList()
                };

                return Ok(cartDto);
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Erreur lors de la récupération du panier: {ex.Message}");
            }
        }

        // Créer un nouveau panier pour l'utilisateur
        [HttpPost]
        public async Task<ActionResult<CartDto>> CreateCart()
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized("Utilisateur non authentifié");
                }

                // Vérifier s'il existe déjà un panier actif
                var existingCart = await _context.Carts
                    .FirstOrDefaultAsync(c => c.MobileUserId == int.Parse(userId) && c.IsActive);

                if (existingCart != null)
                {
                    return Ok(new { Message = "Un panier actif existe déjà", CartId = existingCart.Id });
                }

                // Créer un nouveau panier
                var newCart = new Cart
                {
                    MobileUserId = int.Parse(userId),
                    CreatedAt = DateTime.UtcNow,
                    IsActive = true
                };

                _context.Carts.Add(newCart);
                await _context.SaveChangesAsync();

                return Created(string.Empty, new { CartId = newCart.Id });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Erreur lors de la création du panier: {ex.Message}");
            }
        }

        // Ajouter un article au panier
        [HttpPost("items")]
        public async Task<ActionResult> AddItemToCart([FromBody] AddCartItemDto model)
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

                // Récupérer le panier actif
                var cart = await _context.Carts
                    .Include(c => c.Items)
                    .FirstOrDefaultAsync(c => c.MobileUserId == int.Parse(userId) && c.IsActive);

                // Si aucun panier actif n'existe, en créer un nouveau
                if (cart == null)
                {
                    cart = new Cart
                    {
                        MobileUserId = int.Parse(userId),
                        CreatedAt = DateTime.UtcNow,
                        IsActive = true,
                        Items = new List<CartItem>()
                    };
                    _context.Carts.Add(cart);
                }

                // Vérifier si le produit existe
                var product = await _context.Products.FindAsync(model.ProductId);
                if (product == null)
                {
                    return NotFound("Produit non trouvé");
                }

                // Vérifier si la quantité demandée est disponible
                if (model.Quantity > product.Quantity)
                {
                    return BadRequest($"La quantité demandée ({model.Quantity}) dépasse le stock disponible ({product.Quantity})");
                }

                // Vérifier si l'article existe déjà dans le panier
                var existingItem = cart.Items.FirstOrDefault(ci => ci.ProductId == model.ProductId);
                if (existingItem != null)
                {
                    // Mettre à jour la quantité
                    existingItem.Quantity += model.Quantity;
                    
                    // Vérifier à nouveau si la quantité totale ne dépasse pas le stock
                    if (existingItem.Quantity > product.Quantity)
                    {
                        return BadRequest($"La quantité totale demandée ({existingItem.Quantity}) dépasse le stock disponible ({product.Quantity})");
                    }
                }
                else
                {
                    // Ajouter un nouvel article
                    var newItem = new CartItem
                    {
                        CartId = cart.Id,
                        ProductId = model.ProductId,
                        Quantity = model.Quantity,
                        Price = product.Price
                    };
                    cart.Items.Add(newItem);
                }

                await _context.SaveChangesAsync();
                return Ok(new { Message = "Article ajouté au panier avec succès" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Erreur lors de l'ajout au panier: {ex.Message}");
            }
        }

        // Mettre à jour la quantité d'un article dans le panier
        [HttpPut("items/{productId}")]
        public async Task<ActionResult> UpdateCartItem(int productId, [FromBody] UpdateCartItemDto model)
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

                // Récupérer le panier actif
                var cart = await _context.Carts
                    .Include(c => c.Items)
                    .FirstOrDefaultAsync(c => c.MobileUserId == int.Parse(userId) && c.IsActive);

                if (cart == null)
                {
                    return NotFound("Aucun panier actif trouvé");
                }

                // Récupérer l'article du panier
                var cartItem = cart.Items.FirstOrDefault(ci => ci.ProductId == productId);
                if (cartItem == null)
                {
                    return NotFound("Article non trouvé dans le panier");
                }

                // Vérifier si le produit existe
                var product = await _context.Products.FindAsync(productId);
                if (product == null)
                {
                    return NotFound("Produit non trouvé");
                }

                // Vérifier si la quantité demandée est disponible
                if (model.Quantity > product.Quantity)
                {
                    return BadRequest($"La quantité demandée ({model.Quantity}) dépasse le stock disponible ({product.Quantity})");
                }

                // Mettre à jour la quantité
                cartItem.Quantity = model.Quantity;
                await _context.SaveChangesAsync();

                return Ok(new { Message = "Quantité mise à jour avec succès" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Erreur lors de la mise à jour de l'article: {ex.Message}");
            }
        }

        // Supprimer un article du panier
        [HttpDelete("items/{productId}")]
        public async Task<ActionResult> RemoveCartItem(int productId)
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized("Utilisateur non authentifié");
                }

                // Récupérer le panier actif
                var cart = await _context.Carts
                    .Include(c => c.Items)
                    .FirstOrDefaultAsync(c => c.MobileUserId == int.Parse(userId) && c.IsActive);

                if (cart == null)
                {
                    return NotFound("Aucun panier actif trouvé");
                }

                // Récupérer l'article du panier
                var cartItem = cart.Items.FirstOrDefault(ci => ci.ProductId == productId);
                if (cartItem == null)
                {
                    return NotFound("Article non trouvé dans le panier");
                }

                // Supprimer l'article
                _context.CartItems.Remove(cartItem);
                await _context.SaveChangesAsync();

                return Ok(new { Message = "Article supprimé du panier avec succès" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Erreur lors de la suppression de l'article: {ex.Message}");
            }
        }

        // Vider le panier
        [HttpDelete("items")]
        public async Task<ActionResult> ClearCart()
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
                if (string.IsNullOrEmpty(userId))
                {
                    return Unauthorized("Utilisateur non authentifié");
                }

                // Récupérer le panier actif
                var cart = await _context.Carts
                    .Include(c => c.Items)
                    .FirstOrDefaultAsync(c => c.MobileUserId == int.Parse(userId) && c.IsActive);

                if (cart == null)
                {
                    return NotFound("Aucun panier actif trouvé");
                }

                // Supprimer tous les articles du panier
                _context.CartItems.RemoveRange(cart.Items);
                await _context.SaveChangesAsync();

                return Ok(new { Message = "Panier vidé avec succès" });
            }
            catch (Exception ex)
            {
                return StatusCode(500, $"Erreur lors du vidage du panier: {ex.Message}");
            }
        }
    }

    // DTOs (Data Transfer Objects)
    public class CartDto
    {
        public int Id { get; set; }
        public List<CartItemDto> CartItems { get; set; } = new List<CartItemDto>();
    }

    public class CartItemDto
    {
        public int Id { get; set; }
        public int Quantity { get; set; }
        public ProductDto Product { get; set; }
    }

    public class ProductDto
    {
        public int Id { get; set; }
        public string Barcode { get; set; }
        public string Name { get; set; }
        public string Brand { get; set; }
        public string Category { get; set; }
        public string ImageUrl { get; set; }
        public decimal Price { get; set; }
        public int Quantity { get; set; }
        public int Threshold { get; set; }
    }

    public class AddCartItemDto
    {
        public int ProductId { get; set; }
        public int Quantity { get; set; }
    }

    public class UpdateCartItemDto
    {
        public int Quantity { get; set; }
    }
} 