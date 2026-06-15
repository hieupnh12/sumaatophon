import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.w700)),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            tabs: const [
              Tab(text: 'Ưu đãi'),
              Tab(text: 'Đơn hàng'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PromotionsTab(),
            _OrdersTab(),
          ],
        ),
      ),
    );
  }
}

class _PromotionsTab extends StatelessWidget {
  const _PromotionsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final promotions = [
      {
        'title': '🔥 Flash Sale Đêm Khuya!',
        'subtitle': 'Giảm tới 50% cho dòng iPhone 15 Pro Max và Samsung S24 Ultra. Nhập mã NIGHT50 ngay!',
        'time': '2 giờ trước',
        'icon': Icons.flash_on_rounded,
        'color': Colors.orange,
      },
      {
        'title': '🎉 Ưu Đãi Khách Hàng Mới',
        'subtitle': 'Tặng bạn voucher giảm 20% cho đơn hàng đầu tiên. Mua sắm ngay!',
        'time': '1 ngày trước',
        'icon': Icons.card_giftcard_rounded,
        'color': AppColors.primary,
      },
      {
        'title': '💳 Mở thẻ tín dụng hoàn tiền 2 triệu',
        'subtitle': 'Thanh toán qua thẻ đối tác để nhận hoàn tiền lên đến 2,000,000đ.',
        'time': '3 ngày trước',
        'icon': Icons.credit_card_rounded,
        'color': Colors.blue,
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: promotions.length,
      separatorBuilder: (context, index) => Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1),
      itemBuilder: (context, index) {
        final promo = promotions[index];
        return InkWell(
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (promo['color'] as Color).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(promo['icon'] as IconData, color: promo['color'] as Color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        promo['subtitle'] as String,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        promo['time'] as String,
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.5) : AppColors.lightTextSecondary.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentStep = 2; // Đang giao

    final statuses = [
      {
        'title': 'Đơn hàng đang được giao',
        'subtitle': 'Tài xế Nguyễn Văn A (0901234567) đang trên đường giao iPhone 15 Pro Max đến bạn.',
        'time': 'Hôm nay, 09:15',
        'icon': Icons.local_shipping_rounded,
        'color': Colors.blue,
      },
      {
        'title': 'Đã lấy hàng',
        'subtitle': 'Đơn vị vận chuyển đã lấy hàng thành công từ người bán.',
        'time': 'Hôm qua, 15:20',
        'icon': Icons.inventory_2_rounded,
        'color': Colors.orange,
      },
      {
        'title': 'Đã xác nhận',
        'subtitle': 'Hệ thống đã xác nhận đơn hàng #VN123457 và người bán đang đóng gói.',
        'time': '2 ngày trước, 18:00',
        'icon': Icons.receipt_long_rounded,
        'color': AppColors.success,
      },
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mã đơn: #VN123457', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    'Xem chi tiết',
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DeliveryProgressBar(currentStep: currentStep, isDark: isDark),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: statuses.length,
            itemBuilder: (context, index) {
              final status = statuses[index];
              final isFirst = index == 0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline vertical line and dot
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(top: 4, bottom: 4),
                            decoration: BoxDecoration(
                              color: isFirst ? (status['color'] as Color) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              shape: BoxShape.circle,
                              border: isFirst
                                  ? Border.all(color: (status['color'] as Color).withValues(alpha: 0.3), width: 3)
                                  : null,
                            ),
                          ),
                          if (index != statuses.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                status['title'] as String,
                                style: TextStyle(
                                  fontWeight: isFirst ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 16,
                                  color: isFirst ? (isDark ? Colors.white : Colors.black87) : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                status['subtitle'] as String,
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                status['time'] as String,
                                style: TextStyle(
                                  color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.5) : AppColors.lightTextSecondary.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeliveryProgressBar extends StatelessWidget {
  final int currentStep;
  final bool isDark;

  const _DeliveryProgressBar({required this.currentStep, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final steps = ['Xác nhận', 'Lấy hàng', 'Đang giao', 'Hoàn tất'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        final isLast = index == steps.length - 1;

        final content = Column(
          crossAxisAlignment: isLast ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    shape: BoxShape.circle,
                    border: isActive
                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 4)
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isActive && index < currentStep
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Transform.translate(
              offset: isLast ? const Offset(8, 0) : const Offset(-4, 0),
              child: Text(
                steps[index],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ),
          ],
        );

        if (isLast) {
          return content;
        }

        return Expanded(
          child: content,
        );
      }),
    );
  }
}
