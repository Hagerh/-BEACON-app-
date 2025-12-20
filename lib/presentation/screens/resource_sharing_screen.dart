import 'package:flutter/material.dart';
import 'package:projectdemo/presentation/widgets/footer_widget.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/resources.dart';
import '../../data/models/resource_offer.dart';
import 'package:projectdemo/core/services/p2p_service.dart';
import '../../data/models/resource_request.dart';
import '../../data/local/database_helper.dart';

// --- 1. P2P MODELS ---

// --- 3. RESOURCE MANAGER ---

class ResourceManager {
  static final List<String> categories = [
    "All",
    "Medical",
    "Amenities",
    "Clothes",
    "Sanitary",
    "Other",
  ];

  final List<ResourceItem> _items = [];

  final P2PService p2pService;

  ResourceManager({required this.p2pService}) {
    // Listen to incoming P2P resources
    //p2pService.onResourceReceived(_mergeIncomingResource);
    p2pService.resourceStream.listen(_mergeIncomingResource);
    //ResourceManager({required this.p2pService}) {
    //  p2pService.resourceStream.listen(_mergeIncomingResource);
    //}
  }

  List<ResourceItem> getItems(String category) {
    if (category == "All") return _items;
    return _items.where((item) => item.category == category).toList();
  }

  void addOffer({
    required String category,
    required String resourceName,
    required String userName,
    required String deviceId,
    required int qty,
  }) {
    var uuid = const Uuid();
    var existingItemIndex = _items.indexWhere(
      (i) => i.name == resourceName && i.ownerDeviceId == deviceId,
    );

    if (existingItemIndex != -1) {
      var item = _items[existingItemIndex];
      item.offers.add(
        ResourceOffer(
          offerId: uuid.v4(),
          providerDeviceId: deviceId,
          providerName: userName,
          quantity: qty,
        ),
      );
      item.version++;
      // Broadcast updated resource
      p2pService.sendResource(item);
    } else {
      var newItem = ResourceItem(
        resourceId: uuid.v4(),
        name: resourceName,
        category: category,
        ownerDeviceId: deviceId,
        version: 1,
        offers: [
          ResourceOffer(
            offerId: uuid.v4(),
            providerDeviceId: deviceId,
            providerName: userName,
            quantity: qty,
          ),
        ],
      );
      _items.add(newItem);
      // Broadcast new resource
      p2pService.sendResource(newItem);
    }
  }

  void _mergeIncomingResource(ResourceItem incoming) {
    var index = _items.indexWhere((i) => i.resourceId == incoming.resourceId);

    if (index != -1) {
      var existing = _items[index];
      // Only update if incoming version is newer
      if (incoming.version > existing.version) {
        _items[index] = incoming;
      }
    } else {
      _items.add(incoming);
    }
  }
}

// --- 4. UI SCREEN ---

class ResourceSharingScreen extends StatefulWidget {
  final String deviceId;
  final P2PService p2pService;

  const ResourceSharingScreen({
    super.key,
    required this.deviceId,
    required this.p2pService,
  });

  @override
  State<ResourceSharingScreen> createState() => _ResourceSharingScreenState();
}

class _ResourceSharingScreenState extends State<ResourceSharingScreen> {
  late final ResourceManager _dataManager;
  String _selectedCategory = "All";

  String? _userName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _dataManager = ResourceManager(p2pService: widget.p2pService);
    _loadUser();

    _dataManager.p2pService.resourceStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadUser() async {
    final profile = await DatabaseHelper.instance.getUserProfile(
      widget.deviceId,
    );

    setState(() {
      _userName = profile?.name ?? "Unknown";
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
          _buildCategoryFilter(),
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
                      // Create resource request object
                      final request = ResourceRequest(
                        resourceId: item.resourceId,
                        offerId: offer.offerId,
                        requestorDeviceId: widget.deviceId,
                        requestorName: _userName!,
                        quantity: 1, // You can allow user to select quantity
                      );

                      // Send request to the provider
                      _dataManager.p2pService.sendResourceRequest(
                        offer.providerDeviceId,
                        request,
                      );

                      // Show confirmation to the user
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Request sent! Waiting for approval...",
                          ),
                        ),
                      );
                    }
                  : null, // Disable if quantity is 0
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
                    .where((c) => c != "All")
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
                    _dataManager.addOffer(
                      category: selectedCategory!,
                      resourceName: nameController.text.trim(),
                      userName: _userName!,
                      deviceId: widget.deviceId,
                      qty: int.parse(qtyController.text),
                    );
                    Navigator.pop(context);
                    setState(() {});
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
