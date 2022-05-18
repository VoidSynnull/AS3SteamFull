package game.scene.template
{
	import engine.components.Spatial;
	
	import game.components.hit.Gun;

	public class GunData
	{
		public var x:Number;           // where the gun should be positioned after being loaded.
		public var y:Number;       
		public var gunComponent:Gun;   // A component with information about Gun projectiles, etc
		public var target:Spatial;     // an optional spatial to target with this gun.
		public var targetInLocal:Boolean;  // if true, will target in screen space (for targetting input) vs scene space (for targetting characters, etc)
		public var asset:String;       // an asset to load for this gun
		public var interactions:Array; // A list of interactions used to trigger firing.  Should be keyup/down for keyboard, up/down for buttons.
		public var fireKey:int;        // the keyboard key tied to firing for player controlled guns on desktop
		public var autoFire:Boolean;   // should the gun automatially fire (constrained only by Gun.minimumShotInterval)
		public var lockWhenInputInactive:Boolean;  // if a weapon should only aim when input is down, useful for touch input.
		public var allowSleep:Boolean = true;      // if this weapon should go to sleep when offscreen.
		public var ignoreOffscreenSleep:Boolean;  // should the gun stay awake when offscreen.  This should be false for slotted weapons as their sleep is controlled manually.
		public var addToSlot:Boolean;  // If an entity will hold several weapons a 'WeaponSlots' component can be added to keep track of them.
		public var makeActive:Boolean = true;      // If an Entity has several weapons in slots, this will determine if this one is initially 'active' and not sleeping when added. 
	}
}