package game.scenes.survival2.trees.TweenPath
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class TweenPath extends Component
	{
		public var path:Vector.<Point>;
		public var reverse:Boolean;
		public var end:Boolean;
		public var speed:Number;
		public var pointInPath:int;
		public var tweening:Boolean;
		public var play:Boolean;
		public var newPath:Boolean;
		public var reachedPoint:Signal;
		
		public var loopBehaviour:String;
		
		public var turnBehaviour:String;
		
		public static const LOOP:String = "loop";
		public static const REVERSE:String = "reverse";
		public static const STOP:String = "stop";
		
		public static const TURN:String = "turn";
		public static const FACE:String = "face";
		public static const NONE:String = "none";
		
		public function TweenPath(path:Vector.<Point> = null, loopBehaviour:String = STOP, turnBehaviour:String = NONE, speed:Number = 1, play:Boolean = true)
		{
			setPath(path, loopBehaviour, turnBehaviour, speed, play);
			reachedPoint = new Signal(Entity, Boolean);
		}
		
		public function setPath(path:Vector.<Point> = null, loopBehaviour:String = STOP, turnBehaviour:String = NONE, speed:Number = 1, play:Boolean = true):void
		{
			this.path = path;
			this.loopBehaviour = loopBehaviour;
			this.turnBehaviour = turnBehaviour;
			this.speed = speed;
			this.play = play;
			pointInPath = 0;
			tweening = false;
			end = false;
			this.reverse = false;
			newPath = true;
		}
	}
}