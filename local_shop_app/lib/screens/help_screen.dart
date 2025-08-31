import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Getting Started Section
          const Text(
            'Getting Started',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildHelpItem(
            icon: Icons.login,
            title: 'How to Sign Up',
            description: 'Create an account as a customer or business owner. Choose your role during signup.',
          ),
          _buildHelpItem(
            icon: Icons.search,
            title: 'Finding Offers',
            description: 'Use the search bar to find specific offers or browse categories like Food, Fashion, Electronics.',
          ),
          _buildHelpItem(
            icon: Icons.bookmark,
            title: 'Saving Offers',
            description: 'Tap the bookmark icon on any offer to save it for later. View saved offers in the Saved tab.',
          ),

          const SizedBox(height: 32),

          // Features Section
          const Text(
            'Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildHelpItem(
            icon: Icons.share,
            title: 'Sharing Offers',
            description: 'Share interesting offers with friends using the share button on offer cards or details.',
          ),
          _buildHelpItem(
            icon: Icons.notifications,
            title: 'Notifications',
            description: 'Stay updated with new offers and important announcements through push notifications.',
          ),
          _buildHelpItem(
            icon: Icons.location_on,
            title: 'Location Services',
            description: 'Enable location to see offers from nearby businesses and get personalized recommendations.',
          ),

          const SizedBox(height: 32),

          // For Business Owners
          const Text(
            'For Business Owners',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildHelpItem(
            icon: Icons.add_business,
            title: 'Adding Offers',
            description: 'Create and manage your business offers from the dashboard. Include images, descriptions, and discounts.',
          ),
          _buildHelpItem(
            icon: Icons.analytics,
            title: 'Analytics',
            description: 'Track your offer performance with views, saves, and engagement metrics in your dashboard.',
          ),
          _buildHelpItem(
            icon: Icons.edit,
            title: 'Managing Offers',
            description: 'Edit, pause, or delete your offers anytime from the business dashboard.',
          ),

          const SizedBox(height: 32),

          // Troubleshooting
          const Text(
            'Troubleshooting',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildHelpItem(
            icon: Icons.refresh,
            title: 'App Not Loading',
            description: 'Try refreshing the page or clearing your browser cache. Make sure you have a stable internet connection.',
          ),
          _buildHelpItem(
            icon: Icons.login,
            title: 'Login Issues',
            description: 'Ensure your email and password are correct. For Google sign-in, check your internet connection.',
          ),
          _buildHelpItem(
            icon: Icons.image,
            title: 'Images Not Loading',
            description: 'Some offer images may take time to load. If images don\'t appear, try refreshing the offer.',
          ),

          const SizedBox(height: 32),

          // Contact Support
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Need More Help?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you couldn\'t find what you\'re looking for, feel free to contact our support team.',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement contact support functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support contact coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.email),
                    label: const Text('Contact Support'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(
            icon,
            color: Colors.blue,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(description),
        isThreeLine: true,
      ),
    );
  }
}