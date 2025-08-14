import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';

import '../../provider/teacher_profile_provider.dart';

teacherProfileCityBottomSheet({
  required BuildContext context,
  required TeacherProfileProvider provider,
}) =>
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, state) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 5,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Gradient header with title and close icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40), // balancing space
                    const Expanded(
                      child: Center(
                        child: Text(
                          StringHelper.selectCity,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withOpacity(0.9),
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Search bar
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(color: Colors.deepPurple.shade200),
                ),
                child: Center(
                  child: TextFormField(
                    controller: provider.citySearchCont,
                    style: TextStyle(
                      color: Colors.deepPurple.shade700,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: Colors.deepPurple.shade300,
                        fontSize: 18,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.deepPurple.shade300,
                        size: 24,
                      ),
                      labelStyle: TextStyle(
                        color: Colors.deepPurple.shade400,
                        fontSize: 18,
                      ),
                    ),
                    onChanged: (val) {
                      if (val.isNotEmpty) {
                        provider.searchCityList = List.from(provider.cityList.where(
                              (element) =>
                              element.cityName!.toLowerCase().contains(provider.citySearchCont.text.toLowerCase()),
                        ));
                      } else {
                        provider.searchCityList = provider.cityList;
                        provider.notifyListeners();
                      }
                      state(() {});
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // City list
              if (provider.searchCityList.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: provider.searchCityList.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.deepPurple.shade100,
                      thickness: 1,
                      height: 8,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final city = provider.searchCityList[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        splashColor: Colors.deepPurple.shade100,
                        highlightColor: Colors.deepPurple.shade50,
                        onTap: () {
                          provider.cityController.text = city.cityName!;
                          provider.citySearchCont.clear();
                          state(() {});
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          child: Text(
                            city.cityName!,
                            style: TextStyle(
                              color: Colors.deepPurple.shade700,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Center(
                  child: Text(
                    'No cities found',
                    style: TextStyle(
                      color: Colors.deepPurple.shade300,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
