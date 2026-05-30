import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import 'support_map_screen.dart';
class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor:
          Theme.of(context)
              .scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor:
            Theme.of(context)
                .scaffoldBackgroundColor,

        title: const Text('Cài đặt chung'),

        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_rounded),

          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),

        children: [
          // ================= HIỂN THỊ =================

          _sectionTitle(context, 'HIỂN THỊ'),

          const SizedBox(height: 8),

          _settingsCard(
            context,
            children: [
              SwitchListTile(
                title: const Text('Hiện số dư'),

                subtitle: const Text(
                  'Hiển thị số dư trên trang tổng quan',
                ),

                value: settings.showBalance,

                onChanged:
                    settings.setShowBalance,

                activeTrackColor:
                    AppTheme.primary,
              ),

              const Divider(height: 1),

              ListTile(
                leading: Icon(
                  settings.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,

                  color: AppTheme.primary,
                ),

                title:
                    const Text('Giao diện'),

                subtitle: Text(
                  settings.isDarkMode
                      ? 'Tối'
                      : 'Sáng',
                ),

                trailing: Icon(
                  Icons.chevron_right_rounded,

                  color:
                      Theme.of(context)
                          .colorScheme
                          .outline,
                ),

                onTap: () async {
                  await showModalBottomSheet(
                    context: context,

                    backgroundColor:
                        Theme.of(context)
                            .cardColor,

                    shape:
                        const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),

                    builder: (_) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,

                          children: [
                            ListTile(
                              leading: const Icon(
                                Icons.light_mode,
                              ),

                              title:
                                  const Text('Sáng'),

                              trailing:
                                  !settings.isDarkMode
                                      ? const Icon(
                                          Icons.check,
                                          color:
                                              Colors.green,
                                        )
                                      : null,

                              onTap: () async {
                                await settings
                                    .setDarkMode(
                                  false,
                                );

                                if (context.mounted) {
                                  Navigator.pop(
                                    context,
                                  );
                                }
                              },
                            ),

                            ListTile(
                              leading: const Icon(
                                Icons.dark_mode,
                              ),

                              title:
                                  const Text('Tối'),

                              trailing:
                                  settings.isDarkMode
                                      ? const Icon(
                                          Icons.check,
                                          color:
                                              Colors.green,
                                        )
                                      : null,

                              onTap: () async {
                                await settings
                                    .setDarkMode(
                                  true,
                                );

                                if (context.mounted) {
                                  Navigator.pop(
                                    context,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ================= NHẮC NHỞ =================

          _sectionTitle(context, 'NHẮC NHỞ'),

          const SizedBox(height: 8),

          _settingsCard(
            context,
            children: [
              SwitchListTile(
                title: const Text(
                  'Nhắc nhở ghi chép',
                ),

                subtitle: const Text(
                  'Nhắc bạn ghi chép mỗi ngày',
                ),

                value: settings.dailyReminder,

                onChanged:
                    settings.setDailyReminder,

                activeTrackColor:
                    AppTheme.primary,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ================= TIỀN TỆ =================

          _sectionTitle(
            context,
            'ĐƠN VỊ TIỀN TỆ',
          ),

          const SizedBox(height: 8),

          _settingsCard(
            context,
            children: [
              ListTile(
                title:
                    const Text('Đơn vị tiền tệ'),

                trailing: Text(
                  settings.currency,

                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,

                    color: AppTheme.primary,
                  ),
                ),

                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ================= THÔNG TIN =================

          _sectionTitle(context, 'THÔNG TIN'),

          const SizedBox(height: 8),

          _settingsCard(
            context,
            children: [
              ListTile(
                title:
                    const Text('Phiên bản'),

                trailing: Text(
                  '1.0.0',

                  style: TextStyle(
                    color:
                        Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                  ),
                ),
              ),

              const Divider(height: 1),

              ListTile(
  title: const Text('Liên hệ hỗ trợ'),

  trailing: Icon(
    Icons.chevron_right_rounded,
    color: Theme.of(context)
        .colorScheme
        .outline,
  ),

  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SupportMapScreen(),
      ),
    );
  },
),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context,
    String title,
  ) {
    return Text(
      title,

      style: Theme.of(context)
          .textTheme
          .labelMedium
          ?.copyWith(
            color:
                Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,

            fontWeight: FontWeight.w600,

            letterSpacing: 1,
          ),
    );
  }

  Widget _settingsCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context)
                .cardColor,

        borderRadius:
            BorderRadius.circular(
          AppTheme.radiusMd,
        ),
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(children: children),
    );
  }
}