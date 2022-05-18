package game.scenes.shrink.bathroomShrunk02.BathWaterSystem
{
	import game.scenes.shrink.shared.data.ValueCurve.ValueCurve;
	import game.systems.GameSystem;
	
	public class SoapyWaterSystem extends GameSystem
	{
		public function SoapyWaterSystem()
		{
			super(SoapyWaterNode, updateNode);
		}
		
		public function updateNode(node:SoapyWaterNode, time:Number):void
		{
			if(node.soapyWater.time >= 1 && node.soapyWater.filling || node.soapyWater.time <= 0 && !node.soapyWater.filling)
				return;
			
			var timeScale:Number = node.soapyWater.fillTime;
			if(!node.soapyWater.filling)
				timeScale = node.soapyWater.drainTime;
			
			node.soapyWater.time += time / timeScale * node.soapyWater.fillDirection;
			
			if(node.soapyWater.time > 1)
				node.soapyWater.time = 1;
			if(node.soapyWater.time < 0)
				node.soapyWater.time = 0;
			
			var curve:ValueCurve = node.soapyWater.tubFilledCurve;
			
			var value:Number = curve.getValue(node.soapyWater.time);
			
			node.spatial.y = value;
			
			node.soapyWater.soap.scaleY = node.soapyWater.time;
		}
	}
}