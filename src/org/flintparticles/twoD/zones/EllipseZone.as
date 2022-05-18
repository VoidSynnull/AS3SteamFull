/*
 * FLINT PARTICLE SYSTEM
 * .....................
 * 
 * Author: Richard Lord
 * Copyright (c) Richard Lord 2008-2011
 * http://flintparticles.org
 * 
 * 
 * Licence Agreement
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package org.flintparticles.twoD.zones 
{
	import flash.geom.Point;
	
	import org.flintparticles.twoD.particles.Particle2D;

	/**
	 * The EllipseZone zone defines a elliptical zone.
	 * NOTE :: it has not been written to support collision.
	 */

	public class EllipseZone implements Zone2D
	{
		private var _center:Point;
		private var _xRadius:Number;
		private var _yRadius:Number;
		
		private static const TWOPI:Number = Math.PI * 2;
		
		/**
		 * The constructor defines a OvalZone zone.
		 * 
		 * @param center The centre of the disc.
		 * @param outerRadius The radius of the outer edge of the disc.
		 * @param innerRadius If set, this defines the radius of the inner
		 * edge of the disc. Points closer to the center than this inner radius
		 * are excluded from the zone. If this parameter is not set then all 
		 * points inside the outer radius are included in the zone.
		 */
		public function EllipseZone( center:Point = null, xRadius:Number=0, yRadius:Number=0 )
		{
			if( center == null )
			{
				_center = new Point( 0, 0 );
			}
			else
			{
				_center = center;
			}
			_xRadius = xRadius;
			_yRadius = yRadius;
		}
		
		/**
		 * The centre of the disc.
		 */
		public function get center() : Point
		{
			return _center;
		}

		public function set center( value : Point ) : void
		{
			_center = value;
		}

		/**
		 * The x coordinate of the point that is the center of the disc.
		 */
		public function get centerX() : Number
		{
			return _center.x;
		}

		public function set centerX( value : Number ) : void
		{
			_center.x = value;
		}

		/**
		 * The y coordinate of the point that is the center of the disc.
		 */
		public function get centerY() : Number
		{
			return _center.y;
		}

		public function set centerY( value : Number ) : void
		{
			_center.y = value;
		}

		/**
		 * The radius of the inner edge of the disc.
		 */
		public function get xRadius() : Number
		{
			return _xRadius;
		}

		public function set xRadius( value : Number ) : void
		{
			_xRadius = value;
		}

		/**
		 * The radius of the outer edge of the disc.
		 */
		public function get yRadius() : Number
		{
			return _yRadius;
		}

		public function set yRadius( value : Number ) : void
		{
			_yRadius = value;
		}

		/**
		 * The contains method determines whether a point is inside the zone.
		 * This method is used by the initializers and actions that
		 * use the zone. Usually, it need not be called directly by the user.
		 * 
		 * @param x The x coordinate of the location to test for.
		 * @param y The y coordinate of the location to test for.
		 * @return true if point is inside the zone, false if it is outside.
		 */
		public function contains( x:Number, y:Number ):Boolean
		{
// delete   vv   those 2 back slashes to comment out what i have done
			///*// was not working, so I reworked it the way I thought it should work
			var point:Point = new Point(x, y);
			var distance:Number = Point.distance(point, _center);
			var direction:Number = Math.atan2(point.y - _center.y, point.x  - _center.x);
			
			var xDistance:Number = Math.abs(Math.cos(direction) * distance);
			var yDistance:Number = Math.abs(Math.sin(direction) * distance);
			
			if(xDistance > xRadius || yDistance > _yRadius)
				return false;
			
			return true;
			//*/
			x -= Math.abs( x - _center.x );
			y -= Math.abs( y - _center.y );
			return (  ( x <= _xRadius ) && ( y <= _yRadius) );
		}
		
		/**
		 * The getLocation method returns a random point inside the zone.
		 * This method is used by the initializers and actions that
		 * use the zone. Usually, it need not be called directly by the user.
		 * 
		 * @return a random point inside the zone.
		 */
		public function getLocation():Point
		{
			var angle:Number = Math.random() * TWOPI;
			var point:Point = new Point();
			point.x = Math.cos(angle) * ( Math.sqrt(Math.random()) * _xRadius ) + _center.x;
			point.y = Math.sin(angle) * ( Math.sqrt(Math.random()) * _yRadius ) + _center.y;
			return point;
		}
		
		/**
		 * The getArea method returns the size of the zone.
		 * This method is used by the MultiZone class. Usually, 
		 * it need not be called directly by the user.
		 * 
		 * @return a random point inside the zone.
		 */
		public function getArea():Number
		{
			return Math.PI * ( _xRadius * _yRadius );
		}
		
		/**
		 * NOTE :: This method does not work yet. -bard
		 * Manages collisions between a particle and the zone. The particle will collide with the edges of
		 * the disc defined for this zone, from inside or outside the disc.  The collisionRadius of the 
		 * particle is used when calculating the collision.
		 * 
		 * @param particle The particle to be tested for collision with the zone.
		 * @param bounce The coefficient of restitution for the collision.
		 * 
		 * @return Whether a collision occured.
		 */
		public function collideParticle(particle:Particle2D, bounce:Number = 1):Boolean
		{
			return false;
			
			/*
			// TODO :: This has not been adjusted for an ellipse yet
			var outerLimit:Number;
			var xOuterLimit:Number;
			var yOuterLimit:Number;
			var innerLimit:Number;
			var outerLimitSq:Number;
			var innerLimitSq:Number;
			var distanceSq:Number;
			var distance:Number;
			var pdx:Number;
			var pdy:Number;
			var pDistanceSq:Number;
			var adjustSpeed:Number;
			var positionRatio:Number;
			var epsilon:Number = 0.001;
			var dx:Number = particle.x - _center.x;
			var dy:Number = particle.y - _center.y;
			var dotProduct:Number = particle.velX * dx + particle.velY * dy;
			if( dotProduct < 0 ) // moving towards center
			{
				
				xOuterLimit = _xRadius + particle.collisionRadius;
				yOuterLimit = _yRadius + particle.collisionRadius;
				if ( Math.abs( dx ) > xOuterLimit ) return false;
				if ( Math.abs( dy ) > yOuterLimit ) return false;
				
				// TODO :: Not sure if this is necessary?
				//distanceSq = dx * dx + dy * dy;
				//outerLimitSq =  outerLimit * outerLimit;
				//if( distanceSq > outerLimitSq ) return false;
				// Particle is inside outer circle
				
				pdx = particle.previousX - _center.x;
				pdy = particle.previousY - _center.y;
				
				//pDistanceSq = pdx * pdx + pdy * pdy;
	
				if( pdx > xOuterLimit && pdy > yOuterLimit )
				{
					// particle was outside outer circle
					adjustSpeed = ( 1 + bounce ) * dotProduct / distanceSq;
					particle.velX -= adjustSpeed * dx;
					particle.velY -= adjustSpeed * dy;
					
					//distance = Math.sqrt( distanceSq );
					//positionRatio = ( 2 * outerLimit - distance ) / distance + epsilon;
					//particle.x = _center.x + dx * positionRatio;
					//particle.y = _center.y + dy * positionRatio;
					
					particle.x = _center.x + dx * ( ( 2 * xOuterLimit - dx ) / dx + epsilon );
					particle.y = _center.y + dy * ( ( 2 * yOuterLimit - dy ) / dy + epsilon );
					
					return true;
				}
				
				if( pDistanceSq > outerLimitSq )
				{
					// particle was outside outer circle
					adjustSpeed = ( 1 + bounce ) * dotProduct / distanceSq;
					particle.velX -= adjustSpeed * dx;
					particle.velY -= adjustSpeed * dy;
					distance = Math.sqrt( distanceSq );
					positionRatio = ( 2 * outerLimit - distance ) / distance + epsilon;
					particle.x = _center.x + dx * positionRatio;
					particle.y = _center.y + dy * positionRatio;
					return true;
				}
				
				if( _innerRadius != 0 && innerRadius != _outerRadius )
				{
					innerLimit = _innerRadius + particle.collisionRadius;
					if( Math.abs( dx ) > innerLimit ) return false;
					if( Math.abs( dy ) > innerLimit ) return false;
					innerLimitSq = innerLimit * innerLimit;
					if( distanceSq > innerLimitSq ) return false;
					// Particle is inside inner circle
	
					if( pDistanceSq > innerLimitSq )
					{
						// particle was outside inner circle
						adjustSpeed = ( 1 + bounce ) * dotProduct / distanceSq;
						particle.velX -= adjustSpeed * dx;
						particle.velY -= adjustSpeed * dy;
						distance = Math.sqrt( distanceSq );
						positionRatio = ( 2 * innerLimit - distance ) / distance + epsilon;
						particle.x = _center.x + dx * positionRatio;
						particle.y = _center.y + dy * positionRatio;
						return true;
					}
				}
				return false;
			}
			else // moving away from center
			{
				outerLimit = _outerRadius - particle.collisionRadius;
				pdx = particle.previousX - _center.x;
				pdy = particle.previousY - _center.y;
				if( Math.abs( pdx ) > outerLimit ) return false;
				if( Math.abs( pdy ) > outerLimit ) return false;
				pDistanceSq = pdx * pdx + pdy * pdy;
				outerLimitSq = outerLimit * outerLimit;
				if( pDistanceSq > outerLimitSq ) return false;
				// particle was inside outer circle
				
				distanceSq = dx * dx + dy * dy;

				if( _innerRadius != 0 && innerRadius != _outerRadius )
				{
					innerLimit = _innerRadius - particle.collisionRadius;
					innerLimitSq = innerLimit * innerLimit;
					if( pDistanceSq < innerLimitSq && distanceSq >= innerLimitSq )
					{
						// particle was inside inner circle and is outside it
						adjustSpeed = ( 1 + bounce ) * dotProduct / distanceSq;
						particle.velX -= adjustSpeed * dx;
						particle.velY -= adjustSpeed * dy;
						distance = Math.sqrt( distanceSq );
						positionRatio = ( 2 * innerLimit - distance ) / distance - epsilon;
						particle.x = _center.x + dx * positionRatio;
						particle.y = _center.y + dy * positionRatio;
						return true;
					}
				}

				if( distanceSq >= outerLimitSq )
				{
					// Particle is inside outer circle
					adjustSpeed = ( 1 + bounce ) * dotProduct / distanceSq;
					particle.velX -= adjustSpeed * dx;
					particle.velY -= adjustSpeed * dy;
					distance = Math.sqrt( distanceSq );
					positionRatio = ( 2 * outerLimit - distance ) / distance - epsilon;
					particle.x = _center.x + dx * positionRatio;
					particle.y = _center.y + dy * positionRatio;
					return true;
				}
				return false;
				
			}
			*/
		}
	}
}
