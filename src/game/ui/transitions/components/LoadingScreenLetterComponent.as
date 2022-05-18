package game.ui.transitions.components
{	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	public class LoadingScreenLetterComponent extends Component
	{
		public var hitEntity:Entity;
		
		public var idNumber:int;
		
		public var waveTime:Number;
		public var waveSpeed:Number = 0.08;
		public var waveMag:Number = 5; //wave magnitude
		public var damp:Number = 0.8;
		public var k:Number = 0.025; //spring force
		public var maxRepelDistance:Number = 100;
		
		public var startX:Number;
		public var startY:Number;
		public var baseX:Number;
		public var baseY:Number;
		public var ax:Number = 0;
		public var ay:Number = 0;
		public var vx:Number = 0;
		public var vy:Number = 0;
		public var dist:Number = 0;
		public var radians:Number = 0;
		public var dx:Number = 0; //distance from mouse
		public var dy:Number = 0;
		
		public var doWave:Boolean;
		public var hasExtrusion:Boolean;
		public var hasOutline:Boolean;
		
		public function LoadingScreenLetterComponent( spatial:Spatial, number:int, doWave:Boolean, hasExtrusion:Boolean, hasOutline:Boolean, startOffScreen:Boolean = false )
		{
			startX = spatial.x;
			startY = spatial.y;
			baseX = spatial.x;
			baseY = spatial.y;
			if (startOffScreen) {
				baseY = -100;
			}
			idNumber = number;
			waveTime = number*0.6;
			
			this.doWave = doWave;
			this.hasExtrusion = hasExtrusion;
			this.hasOutline = hasOutline;
		}
	}
}