package game.scenes.lands.shared.nodes {

	/**
	 * not any good thing to call this class. stores the hazard collider for the player in lands
	 * to do collision tests which can then be used to decrease the player's life, etc.
	 */

	import ash.core.Node;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.WaterCollider;
	import game.components.hit.CurrentHit;
	import game.scenes.lands.shared.components.Life;
	import game.scenes.virusHunter.heart.components.ColorBlink;

	public class LandHazardNode extends Node {

		public var hazardCollider:HazardCollider;

		public var life:Life;

		public var bitmapCollider:BitmapCollider;

		public var spatial:Spatial;
		// might make this optional.
		public var motion:Motion;

		public var blink:ColorBlink;

		/**
		 * messy add-on to handle lava,water submerge.
		 */
		public var waterCollider:WaterCollider;

		// only triggers for one frame?!?!
		public var current:CurrentHit;

	} // class
	
} // package