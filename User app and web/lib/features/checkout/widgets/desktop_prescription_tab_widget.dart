part of './upload_prescription_widget.dart';

class _DesktopPrescriptionTabWidget extends StatelessWidget {
  const _DesktopPrescriptionTabWidget({required this.title, required this.isSelected, required this.onTap});

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: robotoMedium.copyWith(color: isSelected ? Theme.of(context).textTheme.bodyMedium!.color : Theme.of(context).disabledColor)),
        const SizedBox(height: 6),
        Container(width: 96, height: 2, color: isSelected ? Theme.of(context).primaryColor : Colors.transparent),
      ]),
    );
  }
}
