package game.scenes.con3.shared
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class GauntletResponder extends Component
	{
		public var endPoint:Point;
		public var offset:Point 		=	new Point( 0, 0 );
		public var iteration:Number;
		public var maxCycles:Number		=   3;
		
		public var oneLoop:Boolean 		= 	true;
		public var invalidate:Boolean   =   false;
		public var operator:String		= 	">";
		public var property:String 		= 	"y";
		
		public var handler:Function;
	}
}