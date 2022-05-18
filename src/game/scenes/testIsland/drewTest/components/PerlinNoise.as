package game.scenes.testIsland.drewTest.components
{
	import flash.display.Bitmap;
	import flash.display.PixelSnapping;
	import flash.filters.DisplacementMapFilter;
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import org.as3commons.collections.ArrayList;
	
	public class PerlinNoise extends Component
	{
		private var _initialize:Boolean;
		
		private var _sizeX:int;
		private var _sizeY:int;
		
		private var _seed:int;
		private var _base:Point;
		private var _numOctaves:int;
		private var _channels:int;
		private var _useStitch:Boolean;
		private var _useGrayScale:Boolean;
		private var _useFractalNoise:Boolean;
		private var _offsets:ArrayList;
		private var _speeds:ArrayList;
		
		private var _displacement:DisplacementMapFilter;
		private var _bitmap:Bitmap;
		
		public function PerlinNoise(sizeX:int = 200, sizeY:int = 200, base:Point = null, seed:int = 12345, numOctaves:int = 3)
		{
			this._initialize = true;
			
			if(sizeX < 1) sizeX = 1;
			this._sizeX = sizeX;
			
			if(sizeY < 1) sizeY = 1;
			this._sizeY = sizeY;
			
			if(!base) base = new Point(50, 50);
			this._base = base;
			
			if(numOctaves < 1) numOctaves = 1;
			this._numOctaves = numOctaves;
			
			this._seed = seed;
			this._channels = 12;
			
			this._useStitch = false;
			this._useGrayScale = false;
			this._useFractalNoise = false;
			
			this._offsets = new ArrayList();
			this._speeds = new ArrayList();
			
			
			this._bitmap = new Bitmap(null, PixelSnapping.ALWAYS, true);
		}
		
		public function get initialize():Boolean { return this._initialize; }
		public function set initialize(boolean:Boolean):void { this._initialize = boolean; }
		
		public function get sizeX():int { return this._sizeX; }
		public function set sizeX(x:int):void
		{
			if(x < 1) x = 1;
			this._sizeX = x;
			this._initialize = true;
		}
		
		public function get sizeY():int { return this._sizeY; }
		public function set sizeY(y:int):void
		{
			if(y < 1) y = 1;
			this._sizeY = y;
			this._initialize = true;
		}
		
		public function get seed():int { return this._seed; }
		public function set seed(seed:int):void { this._seed = seed; }
		
		public function get baseX():Number { return this._base.x; }
		public function set baseX(x:Number):void { this._base.x = x; }
		
		public function get baseY():Number { return this._base.y; }
		public function set baseY(y:Number):void { this._base.y = y; }
		
		public function get numOctaves():int { return this._numOctaves; }
		public function set numOctaves(number:int):void
		{
			if(number < 1) number = 1;
			this._numOctaves = number;
			this._initialize = true;
		}
		
		public function get channels():int { return this._channels; }
		public function set channels(channels:int):void { this._channels = channels; }
		
		public function get useStitch():Boolean { return this._useStitch; }
		public function set useStitch(boolean:Boolean):void { this._useStitch = boolean; }
		
		public function get useGrayScale():Boolean { return this._useGrayScale; }
		public function set useGrayScale(boolean:Boolean):void { this._useGrayScale = boolean; }
		
		public function get useFractalNoise():Boolean { return this._useFractalNoise; }
		public function set useFractalNoise(boolean:Boolean):void { this._useFractalNoise = boolean; }
		
		public function get bitmap():Bitmap { return this._bitmap; }
		public function set bitmap(bitmap:Bitmap):void { this._bitmap = bitmap; }
		
		public function get offsets():ArrayList { return this._offsets; }
		public function get speeds():ArrayList { return this._speeds; }
	}
}