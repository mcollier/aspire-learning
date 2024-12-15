namespace WebApplication1.Models
{
    public record Cargo
    {
        public int Id { get; init; }
        public required string Name { get; init; }
        public double Weight { get; init; }
        public required string Destination { get; init; }
    }
}