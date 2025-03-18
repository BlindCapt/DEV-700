using Application.Services;
using Core.Entities;
using Infrastructure.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
// using Microsoft.AspNetCore.Authorization;

namespace API.Controllers
{
    // [Authorize(Policy = "RequireEmployeeRole")]  // Commenté pour permettre l'accès sans authentification
    [Route("api/products")]
    [ApiController]
    public class ProductsController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly ProductService _productService;

        public ProductsController(AppDbContext context, ProductService productService)
        {
            _context = context;
            _productService = productService;
        }

        [HttpGet]  // Ajout d'une route GET simple
        public async Task<IActionResult> GetProducts()
        {
            var products = await _context.Products.ToListAsync();
            return Ok(products);
        }

        [HttpPost]
        public async Task<IActionResult> AddProduct([FromBody] Product product)
        {
            if (string.IsNullOrWhiteSpace(product.Barcode))
            {
                return BadRequest("Barcode is required");
            }

            // Vérifier si le produit existe déjà
            var existingProduct = await _context.Products
                .FirstOrDefaultAsync(p => p.Barcode == product.Barcode);
            
            if (existingProduct != null)
            {
                return Conflict("Un produit avec ce code-barres existe déjà");
            }

            var fetchedProduct = await _productService.FetchProductFromOpenFoodFacts(product.Barcode);
            if (fetchedProduct != null)
            {
                product.Name = fetchedProduct.Name;
                product.Brand = fetchedProduct.Brand;
                product.Category = fetchedProduct.Category;
                product.ImageUrl = fetchedProduct.ImageUrl;
            }

            _context.Products.Add(product);
            await _context.SaveChangesAsync();

            return CreatedAtAction(nameof(GetProductById), new { id = product.Id }, product);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetProductById(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null) return NotFound();

            return Ok(product);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateProduct(int id, [FromBody] Product product)
        {
            if (id != product.Id)
            {
                return BadRequest("L'ID de l'URL ne correspond pas à l'ID du produit");
            }

            var existingProduct = await _context.Products.FindAsync(id);
            if (existingProduct == null)
            {
                return NotFound();
            }

            // Mise à jour uniquement des champs modifiables
            existingProduct.Price = product.Price;
            existingProduct.Threshold = product.Threshold;
            
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!await _context.Products.AnyAsync(p => p.Id == id))
                {
                    return NotFound();
                }
                throw;
            }

            return NoContent();
        }

        [HttpPut("{id}/stock")]
        public async Task<IActionResult> AddStock(int id, [FromBody] AddStockRequest request)
        {
            var existingProduct = await _context.Products.FindAsync(id);
            if (existingProduct == null)
            {
                return NotFound();
            }

            existingProduct.Quantity += request.QuantityToAdd;
            
            try
            {
                await _context.SaveChangesAsync();
                return Ok(existingProduct);
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!await _context.Products.AnyAsync(p => p.Id == id))
                {
                    return NotFound();
                }
                throw;
            }
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null)
            {
                return NotFound();
            }

            _context.Products.Remove(product);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // Endpoint pour rechercher un produit par code-barres
        [HttpGet("barcode/{barcode}")]
        public async Task<IActionResult> GetProductByBarcode(string barcode)
        {
            if (string.IsNullOrWhiteSpace(barcode))
            {
                return BadRequest("Le code-barres ne peut pas être vide");
            }

            // Rechercher dans la base de données
            var product = await _context.Products
                .FirstOrDefaultAsync(p => p.Barcode == barcode);

            if (product != null)
            {
                return Ok(product);
            }

            // Retourner NotFound si le produit n'existe pas dans la base de données
            return NotFound("Ce produit n'est pas disponible à la vente dans notre magasin.");
        }

        public class AddStockRequest
        {
            public int QuantityToAdd { get; set; }
        }
    }
}
