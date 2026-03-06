class Product {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
  });

  final int id;
  final String title;
  final String description;
  final double price;
  final String image;
  final String category;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'No title',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      image: (json['image'] ?? json['thumbnail']) as String? ?? '',
      category: json['category'] as String? ?? 'Unknown',
    );
  }
}
