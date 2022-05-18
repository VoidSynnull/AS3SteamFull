package game.scenes.virusHunter.anteArm.components
{
	import ash.core.Component;
	
	public class MuscleHit extends Component
	{
		public function MuscleHit( startX:Number, startY:Number, startRotation:Number, startScale:Number, endX:Number, endY:Number, endRotation:Number, endScale:Number )
		{
			this.startX = startX;
			this.startY = startY;
			this.startRotation = startRotation;
			this.startScale = startScale;
			this.endX = endX;
			this.endY = endY;
			this.endRotation = endRotation;
			this.endScale = endScale;
		}
		
		public var startX:Number;
		public var startY:Number;
		public var startRotation:Number;
		public var startScale:Number;
		
		public var endX:Number;
		public var endY:Number;
		public var endRotation:Number;
		public var endScale:Number;
	}
}