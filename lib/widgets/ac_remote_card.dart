import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/esp_provider.dart';

/// Premium tactile card for controlling the AC unit via IR.
class AcRemoteCard extends StatelessWidget {
  final bool isConnected;

  const AcRemoteCard({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final espProvider = context.watch<EspProvider>();
    final status = espProvider.status;
    
    final bool isOn = status.acPower;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isOn
            ? (isDark ? AppColors.indigoContainerDark.withValues(alpha: 0.4) : AppColors.indigoContainer.withValues(alpha: 0.5))
            : (isDark ? AppColors.darkCard : AppColors.lightCard),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isOn
              ? AppColors.indigo.withValues(alpha: 0.8)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isOn ? 2 : 1,
        ),
        boxShadow: isOn
            ? [
                BoxShadow(
                  color: AppColors.indigo.withValues(alpha: isDark ? 0.25 : 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isOn
                          ? AppColors.indigo
                          : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.ac_unit_rounded,
                      color: isOn
                          ? Colors.white
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Remote AC',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'IR Emitter (Gree / FLIFE)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: isOn,
                onChanged: isConnected
                    ? (val) {
                        espProvider.sendAcCommand({'power': val});
                      }
                    : null,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.indigo,
                inactiveThumbColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextSecondary,
                inactiveTrackColor: isDark ? AppColors.darkSurface : Colors.grey.shade200,
              ),
            ],
          ),
          
          if (isOn) ...[
            const SizedBox(height: 24),
            // Temperature Control
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRoundButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    if (status.acTemp > 16) {
                      espProvider.sendAcCommand({'temp': status.acTemp - 1});
                    }
                  },
                  isDark: isDark,
                  color: AppColors.indigo,
                ),
                const SizedBox(width: 30),
                Column(
                  children: [
                    Text(
                      '${status.acTemp}°C',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Target Suhu',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 30),
                _buildRoundButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    if (status.acTemp < 30) {
                      espProvider.sendAcCommand({'temp': status.acTemp + 1});
                    }
                  },
                  isDark: isDark,
                  color: AppColors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Mode and Fan Selection
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Mode',
                    value: status.acMode,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Auto')),
                      DropdownMenuItem(value: 1, child: Text('Cool')),
                      DropdownMenuItem(value: 2, child: Text('Dry')),
                      DropdownMenuItem(value: 3, child: Text('Fan')),
                      DropdownMenuItem(value: 4, child: Text('Heat')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        espProvider.sendAcCommand({'mode': val});
                      }
                    },
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Fan',
                    value: status.acFan,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Auto')),
                      DropdownMenuItem(value: 1, child: Text('Min')),
                      DropdownMenuItem(value: 2, child: Text('Med')),
                      DropdownMenuItem(value: 3, child: Text('Max')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        espProvider.sendAcCommand({'fan': val});
                      }
                    },
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Suhu Display',
                    value: status.acDisplayTemp,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Off')),
                      DropdownMenuItem(value: 1, child: Text('Set')),
                      DropdownMenuItem(value: 2, child: Text('Dalam')),
                      DropdownMenuItem(value: 3, child: Text('Luar')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        espProvider.sendAcCommand({'display_temp': val});
                      }
                    },
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Extra Toggles
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildToggleButton(
                        label: 'Swing',
                        icon: Icons.air_rounded,
                        isActive: status.acSwingV,
                        onTap: () => espProvider.sendAcCommand({'swing_v': !status.acSwingV}),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildToggleButton(
                        label: 'Sleep',
                        icon: Icons.nights_stay_rounded,
                        isActive: status.acSleep,
                        onTap: () => espProvider.sendAcCommand({'sleep': !status.acSleep}),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildToggleButton(
                        label: 'Turbo',
                        icon: Icons.speed_rounded,
                        isActive: status.acTurbo,
                        onTap: () => espProvider.sendAcCommand({'turbo': !status.acTurbo}),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildToggleButton(
                        label: 'X-Fan',
                        icon: Icons.toys_rounded,
                        isActive: status.acXFan,
                        onTap: () => espProvider.sendAcCommand({'xfan': !status.acXFan}),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildToggleButton(
                        label: 'I-Feel',
                        icon: Icons.sensors_rounded,
                        isActive: status.acIFeel,
                        onTap: () => espProvider.sendAcCommand({'ifeel': !status.acIFeel}),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildToggleButton(
                        label: 'Light',
                        icon: Icons.lightbulb_rounded,
                        isActive: status.acLight,
                        onTap: () => espProvider.sendAcCommand({'light': !status.acLight}),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required int value,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isActive 
              ? AppColors.indigo.withValues(alpha: 0.15) 
              : (isDark ? AppColors.darkSurface : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive 
                ? AppColors.indigo.withValues(alpha: 0.5) 
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive 
                  ? AppColors.indigo 
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive 
                      ? AppColors.indigo 
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
