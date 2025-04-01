using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Core.Entities;
using Microsoft.AspNetCore.Authorization;
using Application.DTOs;
using System.Security.Claims;

namespace API.Controllers
{
    [Route("api/mobile/invoices")]
    [ApiController]
    [Authorize(Policy = "RequireMobileUser")]
    public class MobileInvoicesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public MobileInvoicesController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/mobile/invoices
        [HttpGet]
        public async Task<ActionResult<IEnumerable<InvoiceDto>>> GetUserInvoices()
        {
            // Récupérer l'ID de l'utilisateur mobile à partir du token JWT
            if (!int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out int userId))
            {
                return Unauthorized();
            }

            var invoices = await _context.Invoices
                .Include(i => i.MobileUser)
                .Where(i => i.MobileUserId == userId)
                .OrderByDescending(i => i.CreatedAt)
                .ToListAsync();

            return Ok(invoices.Select(i => new InvoiceDto
            {
                Id = i.Id,
                InvoiceNumber = i.InvoiceNumber,
                MobileUserId = i.MobileUserId,
                MobileUserName = $"{i.MobileUser.FirstName} {i.MobileUser.LastName}",
                CartId = i.CartId,
                CreatedAt = i.CreatedAt,
                PaidAt = i.PaidAt,
                TotalAmount = i.TotalAmount,
                Status = i.Status.ToString(),
                PaymentMethod = "Paypal",
                PaymentReference = i.PaymentReference,
                BillingAddress = i.BillingAddress,
                Notes = i.Notes
            }));
        }

        // GET: api/mobile/invoices/5
        [HttpGet("{id}")]
        public async Task<ActionResult<InvoiceDto>> GetInvoice(int id)
        {
            // Récupérer l'ID de l'utilisateur mobile à partir du token JWT
            if (!int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out int userId))
            {
                return Unauthorized();
            }

            var invoice = await _context.Invoices
                .Include(i => i.MobileUser)
                .Include(i => i.Cart)
                .ThenInclude(c => c.Items)
                .ThenInclude(i => i.Product)
                .FirstOrDefaultAsync(i => i.Id == id && i.MobileUserId == userId);

            if (invoice == null)
                return NotFound();

            // Construire le DTO avec les détails complets
            var invoiceDto = new InvoiceDto
            {
                Id = invoice.Id,
                InvoiceNumber = invoice.InvoiceNumber,
                MobileUserId = invoice.MobileUserId,
                MobileUserName = $"{invoice.MobileUser.FirstName} {invoice.MobileUser.LastName}",
                CartId = invoice.CartId,
                CreatedAt = invoice.CreatedAt,
                PaidAt = invoice.PaidAt,
                TotalAmount = invoice.TotalAmount,
                Status = invoice.Status.ToString(),
                PaymentMethod = invoice.PaymentMethod,
                PaymentReference = invoice.PaymentReference,
                BillingAddress = invoice.BillingAddress,
                Notes = invoice.Notes
            };

            // Ajouter les détails du panier s'ils existent
            if (invoice.Cart != null)
            {
                var cartDto = new Application.DTOs.CartDto
                {
                    Id = invoice.Cart.Id,
                    CartItems = invoice.Cart.Items.Select(item => new Application.DTOs.CartItemDto
                    {
                        Id = item.Id,
                        Quantity = item.Quantity,
                        Product = new Application.DTOs.ProductDto
                        {
                            Id = item.Product.Id,
                            Name = item.Product.Name,
                            Brand = item.Product.Brand,
                            Category = item.Product.Category,
                            Price = item.Product.Price,
                            ImageUrl = item.Product.ImageUrl
                        }
                    }).ToList()
                };
                
                invoiceDto.Cart = cartDto;
            }

            return invoiceDto;
        }

        // POST: api/mobile/invoices/5/pay
        [HttpPost("{id}/pay")]
        public async Task<IActionResult> PayInvoice(int id, PayInvoiceDto dto)
        {
            // Récupérer l'ID de l'utilisateur mobile à partir du token JWT
            if (!int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out int userId))
            {
                return Unauthorized();
            }

            var invoice = await _context.Invoices
                .FirstOrDefaultAsync(i => i.Id == id && i.MobileUserId == userId);
            
            if (invoice == null)
                return NotFound();
                
            if (invoice.Status == InvoiceStatus.Paid)
                return BadRequest("Cette facture a déjà été payée");
                
            if (invoice.Status == InvoiceStatus.Cancelled)
                return BadRequest("Cette facture a été annulée");
                
            if (invoice.Status == InvoiceStatus.Refunded)
                return BadRequest("Cette facture a été remboursée");

            // Mettre à jour le statut et les informations de paiement
            invoice.Status = InvoiceStatus.Paid;
            invoice.PaidAt = DateTime.UtcNow;
            invoice.PaymentMethod = dto.PaymentMethod;
            invoice.PaymentReference = dto.PaymentReference;

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // POST: api/mobile/invoices/5/cancel
        [HttpPost("{id}/cancel")]
        public async Task<IActionResult> CancelInvoice(int id)
        {
            // Récupérer l'ID de l'utilisateur mobile à partir du token JWT
            if (!int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out int userId))
            {
                return Unauthorized();
            }

            var invoice = await _context.Invoices
                .FirstOrDefaultAsync(i => i.Id == id && i.MobileUserId == userId);
            
            if (invoice == null)
                return NotFound();
                
            if (invoice.Status == InvoiceStatus.Paid)
                return BadRequest("Impossible d'annuler une facture déjà payée");
                
            if (invoice.Status == InvoiceStatus.Refunded)
                return BadRequest("Cette facture a déjà été remboursée");
                
            if (invoice.Status == InvoiceStatus.Cancelled)
                return BadRequest("Cette facture est déjà annulée");

            invoice.Status = InvoiceStatus.Cancelled;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // PUT: api/mobile/invoices/5/billing-address
        [HttpPut("{id}/billing-address")]
        public async Task<IActionResult> UpdateBillingAddress(int id, [FromBody] string billingAddress)
        {
            // Récupérer l'ID de l'utilisateur mobile à partir du token JWT
            if (!int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out int userId))
            {
                return Unauthorized();
            }

            var invoice = await _context.Invoices
                .FirstOrDefaultAsync(i => i.Id == id && i.MobileUserId == userId);
            
            if (invoice == null)
                return NotFound();
                
            if (invoice.Status != InvoiceStatus.Pending)
                return BadRequest("Seules les factures en attente peuvent être modifiées");

            invoice.BillingAddress = billingAddress;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // POST: api/mobile/invoices/cart/{cartId}
        [HttpPost("cart/{cartId}")]
        public async Task<ActionResult<InvoiceDto>> CreateInvoiceFromCart(int cartId, [FromBody] string billingAddress)
        {
            // Récupérer l'ID de l'utilisateur mobile à partir du token JWT
            if (!int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out int userId))
            {
                return Unauthorized();
            }

            var cart = await _context.Carts
                .Include(c => c.Items)
                .ThenInclude(i => i.Product)
                .Include(c => c.MobileUser)
                .FirstOrDefaultAsync(c => c.Id == cartId && c.MobileUserId == userId);

            if (cart == null)
                return NotFound("Panier introuvable");

            if (!cart.IsActive)
                return BadRequest("Le panier n'est pas actif");
                
            if (cart.Items.Count == 0)
                return BadRequest("Le panier est vide");
                
            if (await _context.Invoices.AnyAsync(i => i.CartId == cartId))
                return BadRequest("Une facture existe déjà pour ce panier");

            // Calculer le montant total de la facture
            decimal totalAmount = cart.Items.Sum(i => i.Quantity * i.Product.Price);

            // Générer un numéro de facture unique (par exemple: INV-202405-0001)
            string invoiceNumber = await GenerateInvoiceNumber();

            var invoice = new Invoice
            {
                InvoiceNumber = invoiceNumber,
                MobileUserId = cart.MobileUserId,
                CartId = cart.Id,
                TotalAmount = totalAmount,
                Status = InvoiceStatus.Pending,
                BillingAddress = billingAddress
            };

            _context.Invoices.Add(invoice);
            
            // Marquer le panier comme terminé
            cart.IsActive = false;
            cart.CompletedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            // Créer le DTO de réponse avec les détails du panier
            var invoiceDto = new InvoiceDto
            {
                Id = invoice.Id,
                InvoiceNumber = invoice.InvoiceNumber,
                MobileUserId = invoice.MobileUserId,
                MobileUserName = $"{cart.MobileUser.FirstName} {cart.MobileUser.LastName}",
                CartId = invoice.CartId,
                CreatedAt = invoice.CreatedAt,
                TotalAmount = invoice.TotalAmount,
                Status = invoice.Status.ToString(),
                BillingAddress = invoice.BillingAddress,
                Cart = new Application.DTOs.CartDto
                {
                    Id = cart.Id,
                    CartItems = cart.Items.Select(item => new Application.DTOs.CartItemDto
                    {
                        Id = item.Id,
                        Quantity = item.Quantity,
                        Product = new Application.DTOs.ProductDto
                        {
                            Id = item.Product.Id,
                            Name = item.Product.Name,
                            Brand = item.Product.Brand,
                            Category = item.Product.Category,
                            Price = item.Product.Price,
                            ImageUrl = item.Product.ImageUrl
                        }
                    }).ToList()
                }
            };

            return CreatedAtAction(nameof(GetInvoice), new { id = invoice.Id }, invoiceDto);
        }

        // Méthode privée pour générer un numéro de facture unique
        private async Task<string> GenerateInvoiceNumber()
        {
            // Format: INV-AAAAMM-XXXX (ex: INV-202405-0001)
            string prefix = $"INV-{DateTime.UtcNow:yyyyMM}-";
            
            // Trouver le dernier numéro existant pour ce mois
            var lastInvoice = await _context.Invoices
                .Where(i => i.InvoiceNumber.StartsWith(prefix))
                .OrderByDescending(i => i.InvoiceNumber)
                .FirstOrDefaultAsync();
                
            int nextNumber = 1;
            
            if (lastInvoice != null)
            {
                // Extraire le numéro de séquence du dernier numéro de facture
                var match = System.Text.RegularExpressions.Regex.Match(lastInvoice.InvoiceNumber, @"(\d+)$");
                if (match.Success && int.TryParse(match.Groups[1].Value, out int lastNumber))
                {
                    nextNumber = lastNumber + 1;
                }
            }
            
            return $"{prefix}{nextNumber:D4}";
        }
    }
} 