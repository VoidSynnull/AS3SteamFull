package game.scenes.mocktropica.shared.components
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Spatial;
	import engine.systems.CameraSystem;
	
	import game.scenes.mocktropica.shared.popups.MocktropicaAdvertisementPopup;
	
	public class AdvertisementComponent extends Component
	{	
		public var target:Spatial;
		public var flame:MovieClip;
		public var level:int;
		public var visual:Entity;
		public var hits:int = 0;
		public var maxHits:int;
		public var camera:CameraSystem;
		public var popup:MocktropicaAdvertisementPopup;
		
		public var closePath:String;
		public var clickPath:String;
		
		public var speeds:Vector.<Number> = new <Number>[ 240, 450, 900 ];
		public var state:String =		SPAWN;
		
		public const IDLE:String =		"idle";
		public const SPAWN:String =		"spawn";
		public const SEEK:String =		"seek";
		public const MOVING:String =	"moving";
		public const DEAD:String =		"dead";
	}
}