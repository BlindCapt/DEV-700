using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;
using Core.Entities;

namespace Application.Services
{
    public class ProductService
    {
        private readonly HttpClient _httpClient;

        public ProductService(HttpClient httpClient)
        {
            _httpClient = httpClient;
        }

        public async Task<Product> FetchProductFromOpenFoodFacts(string barcode)
        {
            var url = $"https://world.openfoodfacts.org/api/v2/product/{barcode}.json";
            var response = await _httpClient.GetAsync(url);

            if (!response.IsSuccessStatusCode) return null;

            var json = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(json);

            var root = doc.RootElement;
            if (!root.TryGetProperty("product", out var productElement)) return null;

            return new Product
            {
                Name = productElement.GetProperty("product_name").GetString() ?? "Unknown",
                Price = 0, // Open Food Facts ne fournit pas de prix, à renseigner manuellement
                Quantity = 1,
                Brand = productElement.GetProperty("brands").GetString() ?? "Unknown",
                Category = productElement.GetProperty("categories").GetString() ?? "Unknown",
                ImageUrl = productElement.GetProperty("image_url").GetString() ?? ""
            };
        }
    }
}
