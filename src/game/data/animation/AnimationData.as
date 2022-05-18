package game.data.animation
{
	
	public class AnimationData
	{	
		public var duration:Number;
		public var animClass:Class;
		
		public function AnimationData( animClass:Class = null, duration:Number=NaN ):void
		{
			this.animClass 	= animClass;
			this.duration 	= duration;
		}
		
		public function duplicate():AnimationData
		{
			var animData:AnimationData = new AnimationData();
			animData.animClass 	= this.animClass;
			animData.duration 	= this.duration;
			return animData;
		}
		// probably want to be able to store other behaviors here that could involve the MotionSystem
	}
}