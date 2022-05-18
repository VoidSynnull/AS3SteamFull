package game.scenes.virusHunter.intestineBattle.components
{
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class IntestineBoss extends Component
	{
		public function IntestineBoss()
		{
			this.state = IntestineBoss.IDLE;
		}
		
		public var target:Spatial;
		public var state:String;
		public var vulnerableToTarget:Boolean = false;
		public static const HURT:String = "boss_hurt";
		public static const DIE:String = "boss_die";
		public static const IDLE:String = "boss_idle";
		public static const INTRO:String = "boss_intro";
		public static const BEGIN:String = "begin";
		public static const REVIVE:String = "boss_revive";
		public static const WEAKENED:String = "boss_weakened";
		public static const IDLE_WEAKENED:String = "boss_idleWeakened";
		public static const FOLLOW:String = "follow";
		public static const STRIKE:String = "strike";
		public static const TENTACLE:String = "tentacle";
	}
}