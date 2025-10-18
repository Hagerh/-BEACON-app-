import 'package:flutter/material.dart';
import 'package:projectdemo/constants/colors.dart';
import 'package:projectdemo/presentation/widgets/voice_widget.dart';
import '../widgets/footer_widget.dart';

class ResourceSharingScreen extends StatelessWidget {
  const ResourceSharingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<String>> resourceCategories = {
      "Medical": ["First Aid Kit", "Bandages", "Painkillers", "Antiseptic"],
      "Food & Water": [
        "Bottled Water",
        "Canned Food",
        "Energy Bars",
        "Baby Formula",
      ],
      "Shelter": ["Tents", "Blankets", "Sleeping Bags", "Temporary Beds"],
      "Utilities": [
        "Flashlights",
        "Batteries",
        "Charging Stations",
        "Power Banks",
      ],
      "Other": ["Clothing", "Hygiene Kits", "Fuel", "Transport Help"],
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Resource Sharing"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 235, 200, 200),
                Color.fromARGB(255, 164, 236, 246),
              ],
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                "Request or Offer Essential Resources",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // --- Expandable Resource Sections ---
              ...resourceCategories.entries.map((entry) {
                return _buildResourceSection(context, entry.key, entry.value);
              }),
            ],
          ),
        ),
      ),

      floatingActionButton: const VoiceWidget(),
      bottomNavigationBar: const FooterWidget(currentPage: 1),
    );
  }

  Widget _buildResourceSection(
    BuildContext context,
    String category,
    List<String> items,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ExpansionTile(
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          category,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: items
            .map(
              (item) => ListTile(
                title: Text(item),
                trailing: ElevatedButton(
                  onPressed: () {
                    // TODO: Handle resource request action
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Request sent for $item"),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Request", style: TextStyle(color:AppColors.primaryBackground) ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
