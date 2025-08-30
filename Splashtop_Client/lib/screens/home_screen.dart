import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pc_list_provider.dart';
import '../models/pc.dart';
import '../utils/constants.dart';
import 'streaming_screen_working.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load user's PCs when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PCListProvider>().loadPCs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Computers'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Consumer<PCListProvider>(
        builder: (context, pcProvider, child) {
          if (pcProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (pcProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading computers',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pcProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => pcProvider.loadPCs(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (pcProvider.pcs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.computer_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No computers found',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a computer to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddComputerDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Computer'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => pcProvider.loadPCs(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pcProvider.pcs.length,
              itemBuilder: (context, index) {
                final pc = pcProvider.pcs[index];
                return _buildPCCard(pc);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddComputerDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPCCard(PC pc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _connectToPC(pc),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Platform Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: pc.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    pc.platformIcon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // PC Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pc.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: pc.statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pc.statusText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: pc.statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (pc.ipAddress != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        pc.ipAddress!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Connect Button
              IconButton(
                onPressed: () => _connectToPC(pc),
                icon: const Icon(Icons.play_arrow),
                style: IconButton.styleFrom(
                  backgroundColor: pc.status == PCStatus.online 
                      ? AppColors.primary 
                      : Colors.grey[300],
                  foregroundColor: pc.status == PCStatus.online 
                      ? Colors.white 
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _connectToPC(PC pc) {
    if (pc.status != PCStatus.online) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pc.name} is not available'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StreamingScreenWorking(
          deviceId: pc.deviceId,
          deviceName: pc.name,
        ),
      ),
    );
  }

  void _showAddComputerDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddComputerDialog(),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class AddComputerDialog extends StatefulWidget {
  const AddComputerDialog({super.key});

  @override
  State<AddComputerDialog> createState() => _AddComputerDialogState();
}

class _AddComputerDialogState extends State<AddComputerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _deviceIdController = TextEditingController();
  PCPlatform _selectedPlatform = PCPlatform.windows;

  @override
  void dispose() {
    _nameController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Computer'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Computer Name',
                hintText: 'e.g., My Desktop',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deviceIdController,
              decoration: const InputDecoration(
                labelText: 'Device ID',
                hintText: 'Unique device identifier',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a device ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PCPlatform>(
              value: _selectedPlatform,
              decoration: const InputDecoration(
                labelText: 'Platform',
              ),
              items: PCPlatform.values.map((platform) {
                return DropdownMenuItem(
                  value: platform,
                  child: Row(
                    children: [
                      Text(platform == PCPlatform.windows ? '🪟' : 
                           platform == PCPlatform.macos ? '🍎' : '🐧'),
                      const SizedBox(width: 8),
                      Text(platform.name.toUpperCase()),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPlatform = value!;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final pcProvider = context.read<PCListProvider>();
              final success = await pcProvider.addPC(
                name: _nameController.text,
                deviceId: _deviceIdController.text,
                platform: _selectedPlatform,
              );
              
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Computer added successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(pcProvider.error ?? 'Failed to add computer'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
