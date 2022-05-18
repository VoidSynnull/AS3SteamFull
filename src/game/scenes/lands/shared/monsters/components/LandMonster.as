package game.scenes.lands.shared.monsters.components {
	
	/**
	 * used for any creature in a land scene, so the monster spawner can remove
	 * all such creatures when a scene changes.
	 *
	 */
	
	import ash.core.Component;
	
	import game.scenes.lands.shared.monsters.MonsterData;
	
	public class LandMonster extends Component {
		
		static public const MEAN:int = 1;
		static public const NEUTRAL:int = 2;
		static public const NICE:int = 3;

		static public const WANDER:int = 1;
		static public const ATTACK:int = 2;
		static public const FOLLOW:int = 3;
		static public const EAT:int = 4;

		/**
		 * Target a tile in lands. most likely a food item?
		 */
		static public const TARGET_TILE:int = 4;
		
		/**
		 * this is currently used for both actions and states, just to save whatever.
		 */
		static public const NONE:int = 0;
		
		/**
		 * monster changes scenes - maybe by following the player, or running off the side.
		 * if true, monster will not be destroyed when the scene changes.
		 */
		public var multiScene:Boolean;
		
		public var mood:int;

		/**
		 * FOR NOW, hunger will not be saved between program runs because the data-hookup has not been made in the xml.
		 * hunger advances 1 point per second. a value of about 600 is hungry ( 10mins )
		 */
		public var hunger:int = 0;

		/**
		 * this is just monster look information but it has to be kept here for data-storage between scenes.
		 */
		public var data:MonsterData;
		
		/**
		 * tracks the mood of the monster in relation to other friendlies.
		 * this will basically be an allegiance or team flag.
		 */
		public var hostility:int;

		/**
		 * current action being performed. pretty shoddy AI for now.
		 */
		public function get action():int {
			return this._action;
		}
		public function set action( new_action:int ):void {

			if ( new_action != this._action ) {
				this._action = new_action;
				this.actionTime = 0;
			}

		} //

		public var _action:int;

		/**
		 * need this to track time in an action to find out if a monster is stuck trying to get food they can't reach?
		 */
		public var actionTime:Number;

		public function LandMonster() {
		}
		
	} // class
	
} // package