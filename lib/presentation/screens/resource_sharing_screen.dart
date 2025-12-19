import 'package:flutter/material.dart';
import 'package:projectdemo/presentation/widgets/footer_widget.dart';

class ResourceOffer {
  final String id;
  final String providerName;
  int quantity;

  ResourceOffer({
    required this.id,
    required this.providerName,
    required this.quantity,
  });
}

class ResourceItem {
  final String name;
  final String category;
  final List<ResourceOffer> offers;

  ResourceItem({
    required this.name,
    required this.category,
    required this.offers,
  });

  int get totalQuantity => offers.fold(0, (sum, item) => sum + item.quantity);
}

class ResourceManager {
  // Pre-defined categories
  static final List<String> categories = [
    "All",
    "Medical",
    "Amenities", // Fixed spelling
    "Clothes",
    "Sanitary",
    "Other",
  ];

  // In-memory storage mimicking a database
  final List<ResourceItem> _items = [
    ResourceItem(name: "Plasters", category: "Medical", offers: []),
    ResourceItem(name: "Water Bottles", category: "Amenities", offers: []),
    ResourceItem(name: "Blankets", category: "Clothes", offers: []),
  ];

  // Get items filtered by category
  List<ResourceItem> getItems(String category) {
    if (category == "All") return _items;
    return _items.where((item) => item.category == category).toList();
  }

  // Add an offer
  void addOffer(
    String category,
    String resourceName,
    String userName,
    int qty,
  ) {
    // Check if resource exists
    var existingItemIndex = _items.indexWhere((i) => i.name == resourceName);

    if (existingItemIndex != -1) {
      // Add offer to existing item
      _items[existingItemIndex].offers.add(
        ResourceOffer(
          id: DateTime.now().toString(),
          providerName: userName,
          quantity: qty,
        ),
      );
    } else {
      // Create new item with the offer
      _items.add(
        ResourceItem(
          name: resourceName,
          category: category,
          offers: [
            ResourceOffer(
              id: DateTime.now().toString(),
              providerName: userName,
              quantity: qty,
            ),
          ],
        ),
      );
    }
  }
}

// --- 3. UI SCREEN ---

class ResourceSharingScreen extends StatefulWidget {
  final String loggedInUserName;
  const ResourceSharingScreen({super.key, this.loggedInUserName = "Alice"});

  @override
  State<ResourceSharingScreen> createState() => _ResourceSharingScreenState();
}

class _ResourceSharingScreenState extends State<ResourceSharingScreen> {
  final ResourceManager _dataManager = ResourceManager(); // Instance of logic
  String _selectedCategory = "All";

  @override
  Widget build(BuildContext context) {
    // Fetch data based on filter
    final displayedResources = _dataManager.getItems(_selectedCategory);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Resource Sharing"),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEBC8C8), Color(0xFFA4ECF6)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // --- Category Filter Chips ---
          _buildCategoryFilter(),

          // --- Resource List ---
          Expanded(
            child: displayedResources.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: displayedResources.length,
                    itemBuilder: (context, index) {
                      return _buildResourceCard(displayedResources[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOfferModal(context),
        label: const Text("Offer Resource"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
      bottomNavigationBar: const FooterWidget(currentPage: 1),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: ResourceManager.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = ResourceManager.categories[index];
          final isSelected = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            selectedColor: const Color(0xFFA4ECF6),
            onSelected: (bool selected) {
              setState(() {
                _selectedCategory = cat;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildResourceCard(ResourceItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: Text(
            item.totalQuantity.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text("${item.offers.length} active offers"),
        children: item.offers.map((offer) {
          return ListTile(
            contentPadding: const EdgeInsets.only(left: 72, right: 16),
            title: Text(offer.providerName),
            subtitle: Text("Available: ${offer.quantity}"),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade400,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: offer.quantity > 0
                  ? () {
                      setState(() {
                        offer.quantity--;
                        if (offer.quantity <= 0) {
                          item.offers.remove(offer);
                        }
                      });
                    }
                  : null,
              child: const Text("Request"),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No resources found in $_selectedCategory",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // --- ADD OFFER LOGIC ---

  void _showAddOfferModal(BuildContext context) {
    String? selectedCategory;
    final nameController = TextEditingController();
    final qtyController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Share a Resource",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Category",
                ),
                items: ResourceManager.categories
                    .where((c) => c != "All") // Don't show "All" in dropdown
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => selectedCategory = v,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Resource Name (e.g. Bandages)",
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Quantity",
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (selectedCategory != null &&
                      nameController.text.isNotEmpty &&
                      qtyController.text.isNotEmpty) {
                    setState(() {
                      _dataManager.addOffer(
                        selectedCategory!,
                        nameController.text.trim(),
                        widget.loggedInUserName,
                        int.parse(qtyController.text),
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.teal,
                ),
                child: const Text(
                  "Submit Offer",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
