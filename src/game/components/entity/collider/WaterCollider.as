/**
 * A component to allow entities to collide with water.
 */ 

package game.components.entity.collider 
{
	import ash.core.Component;

	public class WaterCollider extends Component
	{
		public var isHit:Boolean;					// if collider is in contact with Water hit
		public var surface:Boolean = false;  		// Is the entity on the 'surface' of the hit area?
		public var entered:Boolean = false; 		// This is a 'toggle' to determine when enity enters the water initially, used to trigger create splash particles.
		public var density:Number = .8;      		// The density of the object (used to determine buoyancy) .8 is density of a character
		public var surfaceResistance:Number = .5;	// dampener on velocity when entering Water Hit
		public var dampener:Number = 1;				// dampener applied to buoyancy force, drag defined by collider as opposed to viscosity defined by the hit, higher number will create more 'bobbing' at surface
		public var float:Boolean = true;			// if entity sinks or floats, for character determines swim state.	TODO :: Can phase out this flag
		public var percentSubmerged:Number = 0;		// percentage of total height that is submerged in water, 1 is fully submerged
		public var viscosity:Number;				// viscosity of the fluid the collider is currently in contact with, acts as a velocity dampener
		public var densityHit:Number = .65;			// density of the fluid the collider is currently in cotact with (used to determine buoyancy) water is 1 by default
		public var depth:Number = 0;				
		public var ignoreSplash:Boolean = false;
		public var hitTimer:int = 0;				// necessary for other bitmap collisions, such as walls, so that water does not deactivate immediately
		public var surfaceOffset:Number = 0;
		
		public var floatAtSurface:Boolean = false;
		public var isPet:Boolean = false;
	}
}
