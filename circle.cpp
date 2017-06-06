class circleType {
public:
  void setRadius(double r);
  // Function to set the radius.
  // Postcondition: if (r >= 0) radius = r;
  // otherwise radius = 0;
  double getRadius();
  // Function to return the radius.
  // Postcondition: The value of radius is returned.
  double area();
  // Function to return the area of a circle.
  // Postcondition: Area is calculated and returned.
  double circumference();
  // Function to return the circumference of a circle.
  // Postcondition: Circumference is calculated and returned.
  circleType(double r = 0);
  // Constructor with a default parameter.
  // Radius is set according to the parameter.
  // The default value of the radius is 0.0;
  // Postcondition: radius = r;
private:
  double radius;
};
void circleType::setRadius(double r) {
  if (r >= 0)
    radius = r;
  else
    radius = 0;
}
double circleType::getRadius() { return radius; }
double circleType::area() { return 3.1416 * radius * radius; }
double circleType::circumference() { return 2 * 3.1416 * radius; }
circleType::circleType(double r) { setRadius(r); }
// The user program that uses the class circleType
//#include "circleType.h"
#include <iomanip>
#include <iostream>
using namespace std;
int main()                                       // Line 1
{                                                // Line 2
  circleType circle1(8);                         // Line 3
  circleType circle2;                            // Line 4
  double radius;                                 // Line 5
  cout << fixed << showpoint << setprecision(2); // Line 6
  cout << "radius: " << circle1.getRadius() << ", area: " << circle1.area()
       << ", circumference: " << circle1.circumference() << endl; // Line 7
  cout << "radius: " << circle2.getRadius() << ", area: " << circle2.area()
       << ", circumference: " << circle2.circumference() << endl
       << endl;                                         // Line 8
  cout << "Line 9: Enter the radius of a circle: ";     // Line 9
  cin >> radius;                                        // Line 10
  cout << endl;                                         // Line 11
  circle2.setRadius(radius);                            // Line 12
  cout << "Line 13: After setting the radius." << endl; // Line 13
  cout << "Line 14: circle2 - "
       << "radius: " << circle2.getRadius() << ", area: " << circle2.area()
       << ", circumference: " << circle2.circumference() << endl; // Line 14
  return 0;                                                       // Line 15
} // end main