import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class FoodCarousel extends StatelessWidget {
  final List<String> imageUrls = [
    'assets/images/solid_foods.png',
    'assets/images/fast_foods.png',
    'assets/images/drinks.png',
    'assets/images/liquid_foods.png',
    'assets/images/morning_meal.png',
    'assets/images/liquid_foods.png',
  ];

  FoodCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
        height: 160,
        enlargeCenterPage: true,
        viewportFraction: 0.7,
        initialPage: 1,
        scrollPhysics: const BouncingScrollPhysics(),
      ),
      items: imageUrls.map((url) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              margin: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [Image.asset(url, fit: BoxFit.cover, width: double.infinity, height: double.infinity)],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
