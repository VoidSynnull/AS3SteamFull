package game.scenes.virusHunter.anteArm.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class Muscle extends Component
	{
		public function Muscle( maxExpansion:Number, axis:String, time:Number, muscleHits:Vector.<MuscleHit>, acidHits:Vector.<MuscleHit> )
		{
			this.maxExpansion = maxExpansion;
			this.axis = axis;
			this.time = time;
			this.muscleHits = muscleHits;
			this.acidHits = acidHits;
		}
		///////
		public var init:Boolean = false;
		///////
		
		public var maxExpansion:Number;
		public var axis:String;
		public var time:Number;
		public var muscleHits:Vector.<MuscleHit> = new Vector.<MuscleHit>;
		public var acidHits:Vector.<MuscleHit> = new Vector.<MuscleHit>;
		
		public var hits:Vector.<Entity> = new Vector.<Entity>;
		public var acid:Vector.<Entity> = new Vector.<Entity>;
	}
}