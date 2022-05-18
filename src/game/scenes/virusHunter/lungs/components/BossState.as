package game.scenes.virusHunter.lungs.components
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.as3commons.collections.ArrayList;
	
	public class BossState extends Component
	{
		public static const NO_STATE:String				= "no_state";
		public static const INTRO_STATE:String 			= "intro_state";
		public static const IDLE_STATE:String 			= "idle_state";
		public static const IDLE_MOVE_STATE:String		= "idle_move_state";
		public static const ATTACK_MOVE_STATE:String	= "attack_move_state";
		public static const ATTACK_STATE:String			= "attack_state";
		public static const HURT_STATE:String			= "hurt_state";
		public static const RETREAT_STATE:String 		= "retreat_state";
		public static const DEAD_STATE:String 			= "dead_state";
		
		public static const LUNG_RIGHT:String			= "lung_left";
		public static const LUNG_LEFT:String			= "lung_right";
		
		public var state:String;
		
		public var currentIndex:uint;
		public var remainingSides:ArrayList;
		
		public var currentLung:String;
		
		//Retreat paths from lungs
		public var pathToLeft:Vector.<Point>;
		public var pathToRight:Vector.<Point>;
		
		public var target:Point;
		public var alveoli:Entity;
		
		public function BossState()
		{
			this.state = BossState.NO_STATE;
			this.currentLung = BossState.LUNG_LEFT;
			
			this.remainingSides = new ArrayList();
			this.remainingSides.addAllAt(0, [0, 1, 2, 3]);
			
			this.pathToRight = new Vector.<Point>();
			this.pathToRight.push(new Point(1500, 1800));
			this.pathToRight.push(new Point(2800, 1100));
			this.pathToRight.push(new Point(4100, 1800));
			this.pathToRight.push(new Point(4400, 3200));
			
			this.pathToLeft = new Vector.<Point>();
			this.pathToLeft.push(new Point(4100, 1800));
			this.pathToLeft.push(new Point(2800, 1100));
			this.pathToLeft.push(new Point(1500, 1800));
			this.pathToLeft.push(new Point(1100, 3200));
		}
	}
}