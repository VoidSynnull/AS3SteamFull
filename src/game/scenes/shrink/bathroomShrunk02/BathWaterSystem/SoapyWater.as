package game.scenes.shrink.bathroomShrunk02.BathWaterSystem
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	import game.scenes.shrink.shared.data.ValueCurve.ValueCurve;
	
	public class SoapyWater extends Component
	{
		public var soap:Spatial;
		public var time:Number;
		
		public var fillTime:Number;
		public var drainTime:Number;
		
		public var fillDirection:Number;
		
		public var tubFilledCurve:ValueCurve;
		
		public function SoapyWater(soap:Spatial, filledHeight:Number, drainedHeight:Number, fillTime:Number = 8, drainTime:Number = 16, filled:Boolean = false)
		{
			this.soap = soap;
			this.fillTime = fillTime;
			this.drainTime = drainTime;
			
			time = (filled)?.99:.01;
			filling = filled;
			tubFilledCurve = new ValueCurve(null, new Point(drainedHeight, filledHeight));
		}
		
		public function get filling():Boolean{return fillDirection > 0;}
		public function set filling(fill:Boolean):void{fillDirection = (fill)?1:-1;}
	}
}