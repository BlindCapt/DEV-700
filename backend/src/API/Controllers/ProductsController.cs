using Application.Services;
using Core.Entities;
using Infrastructure.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace API.Controllers
{
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
    }
}
