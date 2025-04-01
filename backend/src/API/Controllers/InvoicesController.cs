using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Infrastructure.Data;
using Core.Entities;
using Microsoft.AspNetCore.Authorization;
using System;
using System.Text.RegularExpressions;
using Application.DTOs;

namespace API.Controllers
{
    [Route("api/invoices")]
    [ApiController]
    public class InvoicesController : ControllerBase
    {
        private readonly AppDbContext _context;

        public InvoicesController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/invoices
        [HttpGet]
        [Authorize]
        public async Task<ActionResult<IEnumerable<InvoiceDto>>> GetInvoices()
        {
            var invoices = await _context.Invoices
                .Include(i => i.MobileUser)
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

        // GET: api/invoices/5
        [HttpGet("{id}")]
        [Authorize]
        public async Task<ActionResult<InvoiceDto>> GetInvoice(int id)
        {
            var invoice = await _context.Invoices
                .Include(i => i.MobileUser)
                .Include(i => i.Cart)
                .ThenInclude(c => c.Items)
                .ThenInclude(i => i.Product)
                .FirstOrDefaultAsync(i => i.Id == id);

            if (invoice == null)
                return NotFound();

            // Vérifier que l'utilisateur mobile a accès à sa propre facture ou que c'est un utilisateur web
            var userIdClaim = User.FindFirst("UserId")?.Value;
            var userTypeClaim = User.FindFirst("UserType")?.Value;

            if (userTypeClaim == "Mobile" && int.TryParse(userIdClaim, out int userId) && userId != invoice.MobileUserId)
            {
                return Forbid();
            }

            return new InvoiceDto
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
        }

        // GET: api/invoices/user/{userId}
        [HttpGet("user/{userId}")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<InvoiceDto>>> GetUserInvoices(int userId)
        {
            // Vérifier que l'utilisateur mobile a accès à ses propres factures ou que c'est un utilisateur web
            var userIdClaim = User.FindFirst("UserId")?.Value;
            var userTypeClaim = User.FindFirst("UserType")?.Value;

            if (userTypeClaim == "Mobile" && int.TryParse(userIdClaim, out int authenticatedUserId) && authenticatedUserId != userId)
            {
                return Forbid();
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
                PaymentMethod = i.PaymentMethod,
                PaymentReference = i.PaymentReference,
                BillingAddress = i.BillingAddress,
                Notes = i.Notes
            }));
        }

        // POST: api/invoices
        [HttpPost]
        [Authorize]
        public async Task<ActionResult<InvoiceDto>> CreateInvoice(CreateInvoiceDto dto)
        {
            var cart = await _context.Carts
                .Include(c => c.Items)
                .ThenInclude(i => i.Product)
                .Include(c => c.MobileUser)
                .FirstOrDefaultAsync(c => c.Id == dto.CartId);

            if (cart == null)
                return NotFound("Panier introuvable");

            if (!cart.IsActive)
                return BadRequest("Le panier n'est pas actif");
                
            if (cart.Items.Count == 0)
                return BadRequest("Le panier est vide");
                
            if (await _context.Invoices.AnyAsync(i => i.CartId == dto.CartId))
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
                BillingAddress = dto.BillingAddress,
                Notes = dto.Notes
            };

            _context.Invoices.Add(invoice);
            
            // Marquer le panier comme terminé
            cart.IsActive = false;
            cart.CompletedAt = DateTime.UtcNow;

            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetInvoice), new { id = invoice.Id }, new InvoiceDto
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
                Notes = invoice.Notes
            });
        }

        // PUT: api/invoices/5
        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> UpdateInvoice(int id, UpdateInvoiceDto dto)
        {
            var invoice = await _context.Invoices.FindAsync(id);
            
            if (invoice == null)
                return NotFound();

            // Mettre à jour les propriétés modifiables
            invoice.BillingAddress = dto.BillingAddress ?? invoice.BillingAddress;
            invoice.Notes = dto.Notes ?? invoice.Notes;
            invoice.PaymentMethod = dto.PaymentMethod ?? invoice.PaymentMethod;
            invoice.PaymentReference = dto.PaymentReference ?? invoice.PaymentReference;
            invoice.Status = dto.Status;
            
            // Si l'état change à "Payé", enregistrer la date de paiement
            if (dto.Status == InvoiceStatus.Paid && invoice.PaidAt == null)
            {
                invoice.PaidAt = DateTime.UtcNow;
            }
            
            // Si l'état change depuis "Payé", effacer la date de paiement
            if (dto.Status != InvoiceStatus.Paid)
            {
                invoice.PaidAt = null;
            }

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // POST: api/invoices/5/pay
        [HttpPost("{id}/pay")]
        [Authorize]
        public async Task<IActionResult> PayInvoice(int id, PayInvoiceDto dto)
        {
            var invoice = await _context.Invoices.FindAsync(id);
            
            if (invoice == null)
                return NotFound();
                
            if (invoice.Status == InvoiceStatus.Paid)
                return BadRequest("Cette facture a déjà été payée");
                
            if (invoice.Status == InvoiceStatus.Cancelled)
                return BadRequest("Cette facture a été annulée");
                
            if (invoice.Status == InvoiceStatus.Refunded)
                return BadRequest("Cette facture a été remboursée");

            // Vérifier que l'utilisateur mobile a accès à sa propre facture ou que c'est un utilisateur web
            var userIdClaim = User.FindFirst("UserId")?.Value;
            var userTypeClaim = User.FindFirst("UserType")?.Value;

            if (userTypeClaim == "Mobile" && int.TryParse(userIdClaim, out int userId) && userId != invoice.MobileUserId)
            {
                return Forbid();
            }

            // Mettre à jour le statut et les informations de paiement
            invoice.Status = InvoiceStatus.Paid;
            invoice.PaidAt = DateTime.UtcNow;
            invoice.PaymentMethod = dto.PaymentMethod;
            invoice.PaymentReference = dto.PaymentReference;

            await _context.SaveChangesAsync();

            return NoContent();
        }

        // DELETE: api/invoices/5
        [HttpDelete("{id}")]
        [Authorize]
        public async Task<IActionResult> DeleteInvoice(int id)
        {
            var invoice = await _context.Invoices.FindAsync(id);
            
            if (invoice == null)
                return NotFound();

            _context.Invoices.Remove(invoice);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // POST: api/invoices/5/cancel
        [HttpPost("{id}/cancel")]
        [Authorize]
        public async Task<IActionResult> CancelInvoice(int id)
        {
            var invoice = await _context.Invoices.FindAsync(id);
            
            if (invoice == null)
                return NotFound();
                
            if (invoice.Status == InvoiceStatus.Paid)
                return BadRequest("Impossible d'annuler une facture déjà payée, utilisez l'option de remboursement à la place");

            invoice.Status = InvoiceStatus.Cancelled;
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // POST: api/invoices/5/refund
        [HttpPost("{id}/refund")]
        [Authorize]
        public async Task<IActionResult> RefundInvoice(int id)
        {
            var invoice = await _context.Invoices.FindAsync(id);
            
            if (invoice == null)
                return NotFound();
                
            if (invoice.Status != InvoiceStatus.Paid)
                return BadRequest("Seules les factures payées peuvent être remboursées");

            invoice.Status = InvoiceStatus.Refunded;
            await _context.SaveChangesAsync();

            return NoContent();
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
                var match = Regex.Match(lastInvoice.InvoiceNumber, @"(\d+)$");
                if (match.Success && int.TryParse(match.Groups[1].Value, out int lastNumber))
                {
                    nextNumber = lastNumber + 1;
                }
            }
            
            return $"{prefix}{nextNumber:D4}";
        }
    }
} 