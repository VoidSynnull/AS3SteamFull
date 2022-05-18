package game.scenes.survival2.shared.components
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class Hook extends Component
	{
		public const START_STATE:int 	= 0;
		public const FALLING_STATE:int	= 1;
		public const HANGING_STATE:int	= 2;
		public const REELING_STATE:int 	= 3;
		public const REELED_STATE:int 	= 4;
		
		public var state:int;
		
		public var reelingVelocity:Number = -100;
		
		public var line:Shape;
		public var lineStart:Point;
		public var lineEnd:Point;
		public var lineLength:Number;
		public var hooked:Boolean = false;
		public var hookedMinY:int = 20;
		public var remove:Boolean = false;
		
		public var poleRotation:Number; //This is how much the item part has been rotated in the fla, in radians.
		public var poleDistance:Number; //How long the fishing pole is in the fla.

		public var bait:String;
		
		public function Hook(lineContainer:DisplayObjectContainer, lineLength:Number, bait:String)
		{
			this.lineLength = lineLength;
			this.bait 		= bait;
			this.lineStart 	= new Point();
			state = START_STATE;
			
			// create line shape // TODO :: would prefer this somewhere else
			this.line 		= new Shape();
			lineContainer.addChildAt(this.line, 0);
		}
		
		override public function destroy():void
		{
			line.graphics.clear();
			line.parent.removeChild( line );
			super.destroy()
		}

	}
}