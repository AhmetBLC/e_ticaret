import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import 'chat_room_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.chat_rounded, color: AppColors.brand, size: 24),
            const SizedBox(width: 8),
            const Text('Mesajlarım'),
          ],
        ),
      ),
      body: chatProvider.loading && chatProvider.conversations.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
          : chatProvider.conversations.isEmpty
              ? _buildEmptyState(theme)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: chatProvider.conversations.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 78,
                    color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
                  ),
                  itemBuilder: (context, index) {
                    final conv = chatProvider.conversations[index];
                    final isSeller = conv.sellerId == authProvider.user?.id;
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
                          image: conv.productImage != null
                              ? DecorationImage(
                                  image: NetworkImage(conv.productImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: conv.productImage == null
                            ? Icon(
                                Icons.shopping_bag_outlined,
                                color: AppColors.brand.withOpacity(0.5),
                              )
                            : null,
                      ),
                      title: Text(
                        conv.getDisplayTitle(authProvider.user?.id ?? ''),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        conv.productTitle ?? 'İlan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatRoomScreen(
                              conversationId: conv.id,
                              title: conv.getDisplayTitle(authProvider.user?.id ?? ''),
                            ),
                          ),
                        ).then((_) => chatProvider.loadConversations());
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.brand.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded, size: 40, color: AppColors.brand.withOpacity(0.5)),
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz mesajınız yok',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlan sahipleriyle konuşmaya başla!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
