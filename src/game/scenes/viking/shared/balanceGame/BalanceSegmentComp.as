package game.scenes.viking.shared.balanceGame
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import org.osflash.signals.Signal;
	
	public class BalanceSegmentComp extends Component
	{
		public function BalanceSegmentComp()
		{
			segments = new Vector.<Entity>();
			failSignal = new Signal();
			warningSignal =  new Signal();
		}
		
		public function findTotalTilt():Number
		{
			totalTilt = 0;
			var seg:BalanceSegment;
			var sp:Spatial;
			for each (var ent:Entity in segments) 
			{
				seg = ent.get(BalanceSegment);
				sp = ent.get(Spatial);
				seg.tilt = sp.rotation;
				//sp.rotation = seg.tilt;
				totalTilt += seg.tilt;
			}
			return totalTilt;
		}
		
		public function addTiltForce(amount:Number):void
		{
			var seg:BalanceSegment;
			var mot:Motion;
			for each (var ent:Entity in segments) 
			{
				seg = ent.get(BalanceSegment);
				mot = ent.get(Motion);
				if(seg.tiltMultiplier > 0){
					mot.rotationVelocity += amount * seg.tiltMultiplier;
					//seg.tilt += amount * seg.tiltMultiplier;
				}
				else{
					//seg.tilt += amount;
					mot.rotationVelocity += amount;
				}
			}
			findTotalTilt();
		}
		
		public function stopTilt():void
		{
			//var seg:BalanceSegment;
			var mot:Motion;
			for each (var ent:Entity in segments) 
			{
				//seg = ent.get(BalanceSegment);
				mot = ent.get(Motion);
				mot.rotationVelocity = 0;
			}
		}
		
		
		override public function destroy():void
		{
			segments.splice(0,segments.length);
			segments = null;
			super.destroy();
		}
		
		public var tilting:Boolean = true;
		
		public var totalTilt:Number = 0;
		public var warningLimit:Number = 50;
		public var tiltLimit:Number = 145;
		public var tiltSpeed:Number = 0.63;
		
		public var segments:Vector.<Entity>;
		
		public var failSignal:Signal;
		public var warningSignal:Signal;
		private var headChar:Entity;
	}
}