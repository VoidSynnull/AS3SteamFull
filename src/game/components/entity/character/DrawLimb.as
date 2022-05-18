package game.components.entity.character
{	
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	import game.data.character.DrawLimbData;
	
	public class DrawLimb extends Component
	{
		public var previousDistX:Number = 0;
		public var previousDistY:Number = 0;
		public var previousColor:uint;
		
		public var leader:Spatial;
		public var lineWidth:Number = 4;
		public var maxDist:Number = 0;  	// 60 if creature?, 80 if not
		public var offset:Number = 0;  		// -40 for standard char
		public var isBendForward:Boolean = false;
		public var pose:Boolean = false;
		
		public function applyData( limbData:DrawLimbData ):void
		{
			this.lineWidth 			= limbData.lineWidth;
			this.maxDist 			= limbData.maxDist;
			this.offset 			= limbData.offset;
			this.isBendForward		= limbData.isBendForward;
		}
	}
}