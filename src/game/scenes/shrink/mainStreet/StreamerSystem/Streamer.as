package game.scenes.shrink.mainStreet.StreamerSystem
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	import game.util.ColorUtil;
	
	public class Streamer extends Component
	{
		public var sectionWidth:Number;
		public var ribbonStartHeight:Number;
		public var ribbonEndHeight:Number;
		public var sections:int;
		
		public var whips:Number;
		public var whipIntensity:Number;
		public var streamer:MovieClip;
		
		public var windDirectionOf:Spatial;
		
		public var points:Vector.<Point>;
		
		public var streamerColor:Number;
		public var lineColor:Number;
		
		public var whipOffset:Number;
		public var whipSpeed:Number;
		
		public var offSetByCamera:Boolean;
		
		public var angleOfFixture:Number;
		
		public var clampPositive:Boolean = false;
		
		public function Streamer(streamer:MovieClip = null, angleOfFixture:Number = 0, windDirectionOf:Spatial = null, offSetByCamera:Boolean = false, whips:Number = 2, whipIntensity:Number = 5, whipSpeed:Number = 1, sections:int = 10, sectionWidth:Number = 15, ribbonStartHeight:Number = 15, ribbonEndHeight:Number = 15, streamerColor:Number = 0x5DA690 )
		{
			whipOffset = 0;
			this.streamer = streamer;
			
			this.angleOfFixture = angleOfFixture;
			this.sections = sections;
			this.sectionWidth = sectionWidth;
			this.ribbonStartHeight = ribbonStartHeight;
			this.ribbonEndHeight = ribbonEndHeight;
			
			this.whips = whips;
			this.whipIntensity = whipIntensity;
			this.whipSpeed = whipSpeed;
			
			this.windDirectionOf = windDirectionOf;
			
			this.offSetByCamera = offSetByCamera;
			
			this.streamerColor = streamerColor;
			lineColor = ColorUtil.darkenColor( this.streamerColor, .3 );
			points = new Vector.<Point>();
			for(var i:int = 0; i < sections; i++)
			{
				points.push(new Point());
			}
		}
	}
}