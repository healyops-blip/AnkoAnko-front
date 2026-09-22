import 'package:flutter/material.dart';

import '../widgets/anko_image.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        key: const Key('profile-screen'),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        children: [
          Text('我的', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  AnkoImage(size: 88),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anko · Lv.6',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text('守护、指引，也记得家的温暖'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _ProfileTile(
            Icons.videocam_outlined,
            '设备与监测覆盖',
            '管理摄像头、门铃与无监测区域',
          ),
          const _ProfileTile(Icons.groups_outlined, '家庭成员与沟通', '成人、老人、儿童的不同入口'),
          const _ProfileTile(
            Icons.lock_outline_rounded,
            '房间与隐私',
            '管理隐藏区域与家庭权限',
          ),
          const _ProfileTile(Icons.history_rounded, '事件记录', '查看证据与处理进度'),
          const _ProfileTile(Icons.settings_outlined, '家庭设置', '家庭名称与初始化'),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile(this.icon, this.title, this.subtitle);

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 8,
          ),
          leading: Icon(icon, color: const Color(0xFF348CD8)),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () =>
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text('$title将在下一阶段接入'))),
        ),
      ),
    );
  }
}
