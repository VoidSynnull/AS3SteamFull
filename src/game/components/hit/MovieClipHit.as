package game.components.hit
{
	import flash.display.DisplayObjectContainer;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class MovieClipHit extends Component
	{
		public function MovieClipHit(type:String = "default", ...allValidHitTypes)
		{
			this.type = type;
			
			this.validHitTypes = new Dictionary();
			
			if(allValidHitTypes.length > 0)
			{
				for(var n:String in allValidHitTypes)
				{
					this.validHitTypes[allValidHitTypes[n]] = true;
				}
			}
			else
			{
				this.validHitTypes["default"] = true;
			}
		}
		
		public var pointHit:Boolean = false;
		public var isHit:Boolean = false;
		
		public var type:String;                         // an optional type for this hit.
		public var validHitTypes:Dictionary;            // an optional dictionary to set which types what this hit is hittested against.  Defaults to being tested against all other movieclip hits.
		public var hitDisplay:DisplayObjectContainer;   // an optional alternate clip if you don't want to use this entities Display.displayObject for hitTests.
		public var collider:Entity;
		public var _colliderId:String;                  // this is set by the movieclip hit system to whatever id is currently being collided with
		private var _shapeHit:Boolean = false;
		
		// used to turn on shape hits for this movieclip.
		public function get shapeHit():Boolean 	{ return _shapeHit; }
		public function set shapeHit( bool:Boolean ):void 
		{
			pointHit = bool;
			_shapeHit = bool;
		}
	}
}