import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sprite_avatar.dart';
import '../../features/common/viewmodels/profile_view_model.dart';

class AvatarSelectorModal {
  static void show(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // All 28 individual avatars
    final allIndices = List.generate(28, (i) => i);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Choisir un Avatar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 32),
            
            // Grid
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: allIndices.length,
                itemBuilder: (context, i) {
                  return InkWell(
                    onTap: () {
                      context.read<ProfileViewModel>().updateProfile(avatarIndex: allIndices[i]);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SpriteAvatar(index: allIndices[i], size: 80),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
