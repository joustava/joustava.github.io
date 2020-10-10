# Linear Algebra



## Vector Basics



### Points and Vectors

> Points and Vectors are two fundamental objects in the space of linear algebra.

A Point is a location in space represented as a dot at certain coordinates. In 2D space, coordinates of a point are denoted in the cartesian system as

​	$ P = (x ,y) $ 

In 3D space as 

​	$ P = (x, y, z) $

A Vector represents a change in position. In euclidian space a vector can be represented as an arrow connecting its origin, a point, to another destination point. A Vector has a magnitude (its length) and a direction denoted as

 	$ {\vec{x}} = \begin{bmatrix} 5\\ 2\\ 6\end{bmatrix} $

Vectors do not have a fixed location as the represent change. Vectors are equal when the represent the same change in each dimension. Points are only equal when they are located at the same place.



### Vector Addition

> Vector addition is done by simply adding the corresponding coordinates.

Notation:

​	$ {\vec{x}} + {\vec{y}} = \vec{z} $	

Process:

​	$ \begin{bmatrix} x_a\\ x_b\\ x_c\end{bmatrix} + \begin{bmatrix} y_a\\ y_b\\ y_c\end{bmatrix} = \begin{bmatrix} x_a + y_a\\ x_b + y_b\\ x_c + y_c\end{bmatrix} $  

Example:

​	$ \begin{bmatrix} 1\\ 2\\ 6\end{bmatrix} + \begin{bmatrix} 5\\ -1\\ 3\end{bmatrix} = \begin{bmatrix} 6\\ 1\\ 9\end{bmatrix} $  



### Vector Subtraction

> Vector subtraction is done by simply subtracting the corresponding coordinates.

Notation:

​	$ {\vec{x}} - {\vec{y}} = \vec{z} $	

Process:

​	$ \begin{bmatrix} x_a\\ x_b\\ x_c\end{bmatrix} - \begin{bmatrix} y_a\\ y_b\\ y_c\end{bmatrix} = \begin{bmatrix} x_a - y_a\\ x_b - y_b\\ x_c - y_c\end{bmatrix} $  

Example:

​	$ \begin{bmatrix} 1\\ 2\\ 6\end{bmatrix} - \begin{bmatrix} 5\\ -1\\ 3\end{bmatrix} = \begin{bmatrix} -4\\ 3\\ 3\end{bmatrix} $  



### Vector Scalar Multiplication

> Vector multiplication by a scalar scales the Vector size.

Notation:

​	$  k{\vec{y}} = \vec{z} $	

Process:

​	$ k\begin{bmatrix} y_a\\ y_b\\ y_c\end{bmatrix} = \begin{bmatrix} ky_a\\ ky_b\\ ky_c\end{bmatrix} $  

Example:

​	$ 5\begin{bmatrix} 5\\ -1\\ 3\end{bmatrix} = \begin{bmatrix} 25\\ -5\\ 15\end{bmatrix} $  



### Vector Magnitude [TBD]

> The magnitude of a Vector is the distance between two points.

Notation:

​	$ \left|\left|{\vec{y}}\right|\right| = \sqrt{V_x^2 + V_y^2} $

or 

​	$ \left|\left|{\vec{v}}\right|\right| = \sqrt{\vec{v} \cdot \vec{v}} $

Process:

​	$ \left|\left|{\vec{y}}\right|\right| = \sqrt{V_x^2 + V_y^2} $



### Unit Vector

> The normalization of a Vector (Unit Vector) means that we try to get a Vector with length of 1.

Notation:

​	$ \vec{u}_\vec{v} = \frac{1}{\left|\left|{\vec{v}}\right|\right|}\vec{v} $ 

Example:

*0. given*

​	$ {\vec{v}} = \begin{bmatrix} -1\\ 1\\ 1\end{bmatrix} $

*1. normalize*

​	$ \left|\left|{\vec{v}}\right|\right| = \sqrt{(-1)^2 + (1)^2 + (1)^2} = \sqrt{3} $

*2. scalar multiplication* to find unit vector

​	$ {\vec{u}} = \frac{1}{\sqrt{3}} \begin{bmatrix} -1\\ 1\\ 1\end{bmatrix} = \begin{bmatrix} \frac{-1}{\sqrt{3}}\\ \frac{1}{\sqrt{3}}\\ \frac{1}{\sqrt{3}}\end{bmatrix}$



### Zero Vector

> A Vector that indicates no change. It's lenght is 0 and has therefor no direction as we cannot find its magnitude.

Notation:

​	$ {\vec{0}} = \begin{bmatrix} 0\\ 0\\ 0\end{bmatrix} $



### Dot Product of two Vectors

> The Dot or Inner Product helps us find find the angle between to Vectors.

Notation:

​	$ \vec{v} \cdot \vec{w} = \left|\left|{\vec{v}}\right|\right| \cdot \left|\left|{\vec{w}}\right|\right| \cdot cos\theta $ 

or 

​	$ \vec{v} \cdot \vec{w} = V_1W_1 + V_2W_2 + ... + V_nW_n $

Process:

​	$ \begin{bmatrix} x_a\\ x_b\\ x_c\end{bmatrix} \cdot \begin{bmatrix} y_a\\ y_b\\ y_c\end{bmatrix} = x_ay_a + x_by_b + x_cy_c $

Example:

​	$ \begin{bmatrix} 1\\ 2\\ -1\end{bmatrix} \cdot \begin{bmatrix} 3\\ 3\\ 0\end{bmatrix} = 1 \cdot 3 + 2 \cdot 1 + -1 \cdot 0 = 5  $  

Note:

> Assuming both V and W are not Zero Vectors.

​	*when*

​		$ \vec{v} \cdot \vec{w} = \left|\left|{\vec{v}}\right|\right| \cdot \left|\left|{\vec{w}}\right|\right| $

​	*then*

​		$ cos\theta = 1 $

​	*and*

​		$ \theta =0 = (0^{\circ}) $

	> Thus both Vectors point in the same direction.

​	*when*

​		$ \vec{v} \cdot \vec{w} = - \left|\left|{\vec{v}}\right|\right| \cdot \left|\left|{\vec{w}}\right|\right| $

​	*then*

​		$ cos\theta = -1 $

​	*and*

​		$ \theta = \pi = (180^{\circ}) $

	> Thus both Vectors point in the opposite direction.

​	*when*

​		$ \vec{v} \cdot \vec{w} = 0 $

​	*then*

​		$ cos\theta = 0 $

​	*and*

​		$ \theta = \frac{\pi}{2} = (90^{\circ}) $

	> Thus both Vectors are at a right angle to each other.



### Parallel and Orthogonal Vectors

> Vectors are parallel if one is a multiple of the other.

Parallel Notation:

​	$ \vec{v} || k\vec{v} $

Orthogonal

​	$  \vec{v} \perp \vec{w} $

Example:

​	$ \vec{v} || 2\vec{v}$ : a vector is parallel to a scaled version of itself

​	$ \vec{v} || -\vec{v} $ : a vector is parallel even if it points in the opposite direction 

​	$ \vec{v} || \vec{0} || 0\vec{v} $ : a vector is parallel to the zero vector

​	$  \vec{v} \perp \vec{w} $ when $  \vec{v} \cdot \vec{w} = 0 $ (either could also be the 0 vector in this case)



### Projecting Vectors [TBD]

> A Vector is the sum of its parallel component and its orthogonal component (in context of a basis vector)

$ proj_\vec{b}(\vec{v}): \vec{v}^{||} = (\vec{v} \cdot \vec{u}_\vec{b}) \vec{u}_\vec{b} $



### Vector Cross Product [TBD]

> Usefulness

Formula:

​	$ \vec{v} = \begin{bmatrix} x_v\\ y_v\\ z_v\end{bmatrix}, \vec{w} = \begin{bmatrix} x_w\\ y_w\\ z_w\end{bmatrix}, then: \vec{v} \times \vec{w} = \begin{bmatrix} y_vz_w - y_wz_v\\ -(x_vz_w - x_wz_v)\\ x_vy_w - x_wy_v\end{bmatrix} $



## Intersections

> Given a set of flat - defined by linear equations - objects, what are their commen points of intersection.