package game.scenes.myth.riverStyx.components
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import engine.components.Audio;
	import engine.components.Display;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	public class StyxComponent extends Component
	{
		public var flameAudio:Audio;	
		public var splashEmitter:Emitter2D;
		public var crocJaw:DisplayObject;
		public var crocBody:DisplayObject;
		public var origin:Point;
		public var state:String = "spawn";
		public var visual:Display;
	}
}