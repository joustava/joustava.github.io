---
draft: true
---
# Linear Algebra



## Vector Basics



### Points and Vectors

> Points and Vectors are two fundamental objects in the space of linear algebra.

A Point is a location in space represented as a dot at certain coordinates. In 2D space, coordinates of a point are denoted in the cartesian system as

​	$ P = (x ,y) $ 

In 3D space as 

​	$ P = (x, y, z) $

A Vector represents a change in position. In euclidian space a vector can be represented as an arrow connecting its origin, a point, to another destination point. A Vector has a magnitude (its length) and a direction denoted as

 	$ {ec{x}} = egin{bmatrix} 5\ 2\ 6nd{bmatrix} $

Vectors do not have a fixed location as the represent change. Vectors are equal when the represent the same change in each dimension. Points are only equal when they are located at the same place.



### Vector Addition

> Vector addition is done by simply adding the corresponding coordinates.

Notation:

​	$ {ec{x}} + {ec{y}} = ec{z} $	

Process:

​	$ egin{bmatrix} x_a\ x_b\ x_cnd{bmatrix} + egin{bmatrix} y_a\ y_b\ y_cnd{bmatrix} = egin{bmatrix} x_a + y_a\ x_b + y_b\ x_c + y_cnd{bmatrix} $  

Example:

​	$ egin{bmatrix} 1\ 2\ 6nd{bmatrix} + egin{bmatrix} 5\ -1\ 3nd{bmatrix} = egin{bmatrix} 6\ 1\ 9nd{bmatrix} $  



### Vector Subtraction

> Vector subtraction is done by simply subtracting the corresponding coordinates.

Notation:

​	$ {ec{x}} - {ec{y}} = ec{z} $	

Process:

​	$ egin{bmatrix} x_a\ x_b\ x_cnd{bmatrix} - egin{bmatrix} y_a\ y_b\ y_cnd{bmatrix} = egin{bmatrix} x_a - y_a\ x_b - y_b\ x_c - y_cnd{bmatrix} $  

Example:

​	$ egin{bmatrix} 1\ 2\ 6nd{bmatrix} - egin{bmatrix} 5\ -1\ 3nd{bmatrix} = egin{bmatrix} -4\ 3\ 3nd{bmatrix} $  



### Vector Scalar Multiplication

> Vector multiplication by a scalar scales the Vector size.

Notation:

​	$  k{ec{y}} = ec{z} $	

Process:

​	$ kegin{bmatrix} y_a\ y_b\ y_cnd{bmatrix} = egin{bmatrix} ky_a\ ky_b\ ky_cnd{bmatrix} $  

Example:

​	$ 5egin{bmatrix} 5\ -1\ 3nd{bmatrix} = egin{bmatrix} 25\ -5\ 15nd{bmatrix} $  



### Vector Magnitude [TBD]

> The magnitude of a Vector is the distance between two points.

Notation:

​	$ \left|\left|{ec{y}}ight|ight| = \sqrt{V_x^2 + V_y^2} $

or 

​	$ \left|\left|{ec{v}}ight|ight| = \sqrt{ec{v} 