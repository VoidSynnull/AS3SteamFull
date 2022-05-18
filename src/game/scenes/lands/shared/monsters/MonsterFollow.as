package game.scenes.lands.shared.monsters {
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.scenes.lands.shared.classes.TileSelector;
	
	/**
	 * Component has information for a monster tracking a Tile location, or an Entity in Poptropica Realms.
	 * This could use some work. I am working on it.
	 */
	public class MonsterFollow extends Component {
		
		public const TARGET_ENTITY:int = 1;
		public const TARGET_TILE:int = 2;
		
		/**
		 * target tile or entity.
		 */
		public var targetMode:int;
		
		public var _tileTarget:TileSelector;
		
		public var _target:Entity;
		
		/**
		 * targetSpatial will be set automatically by the system.
		 */
		public var _targetSpatial:Spatial;
		
		/**
		 * at regular intervals the monster will recheck the distance to the target.
		 * if the distance is too great, the monster will stop following.
		 * this counts down the clock to the next distance check - which does not happen every frame.
		 */
		public var _distCheckTime:Number;
		
		/**
		 * timer counting down until the monster tries to find a new destination.
		 */
		public var _destCheckTime:Number;
		
		/**
		 * squared max distance to target.
		 */
		public var _maxDistanceSqr:Number = 500*500;
		//public var maxDistance:int = 500;
		
		public var _arriveDistanceSqr:Number = 20;
		
		/**
		 * when the monster follows the player offscreen, need to save the dx,dy relative to player
		 * in order to restore it after scene change.
		 */
		public var player_dx:Number;
		public var player_dy:Number;
		
		public function set tileTarget( tileSel:TileSelector ):void {
			
			this._tileTarget = tileSel;
			this.targetMode = TARGET_TILE;
			
		} //
		
		public function get tileTarget():TileSelector {
			return this._tileTarget;
		}
		
		public function set target( e:Entity ):void {
			
			this._target = e;
			this._targetSpatial = e.get( Spatial ) as Spatial;
			this.targetMode = TARGET_ENTITY;
			
		} //
		
		public function get target():Entity {
			return this._target;
		}
		
		public function clearTarget():void {
			this.targetMode = 0;
			this._targetSpatial = null;
			this._target = null;
		} //
		
		public function MonsterFollow( theTarget:Entity ) {
			
			super();
			
			this._target = theTarget;
			this.targetMode = TARGET_ENTITY;
			
		} //
		
	} // class
	
} // package