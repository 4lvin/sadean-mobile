import 'package:flutter/material.dart';

class TopCategoryItem extends StatelessWidget {
  final int rank;
  final String name;
  final int soldCount;

  const TopCategoryItem({
    required this.rank,
    required this.name,
    required this.soldCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColorForRank(rank),
          child: Text(
            '#$rank',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(name),
        trailing: Text(
          '$soldCount terjual',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Color _getColorForRank(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[300]!;
      default:
        return Colors.blue;
    }
  }
}
