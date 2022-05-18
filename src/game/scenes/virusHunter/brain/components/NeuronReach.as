package game.scenes.virusHunter.brain.components
{
	import com.greensock.TweenLite;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import game.scenes.virusHunter.brain.neuron.Neuron;

	public class NeuronReach extends IKReach
	{
		public function NeuronReach($segmentPrefix:String, $display:DisplayObject, $segWidth:Number, $startAtInt:int = 0, $neuron:Neuron = null)
		{
			neuron = $neuron;
			super($segmentPrefix, $display, $segWidth, $startAtInt);
		}
		
		override public function revertToOriginal():void{
			// revert to original "form"
			// have each segment tween back to original form
			if(reverting == false){
				
				reverting = true;
				
				for each(var ikSegment:IKSegment in segments){
					TweenLite.to(ikSegment.display, 1, {x:ikSegment.origPoint.x, y:ikSegment.origPoint.y, rotation:ikSegment.origRotation});
				}
				
				reachPoint = new Point();
				connectedToPoint = null;
				neuron.connectedNeuron = null;
				
				// sever all pulse links
				if(connectedTo){
					var connectedNeuron:Neuron = connectedTo.neuron;
					
					while(connectedNeuron != null){
						connectedNeuron.pulsing = false;
						connectedNeuron = connectedNeuron.connectedNeuron; // next connected Neuron
					}
				}
				
				connectedTo = null;
				connectedBy = null;
				
			}
		}
		
		public var neuron:Neuron;
		public var connectedTo:NeuronReach; // this neuron is connected to ...
		public var connectedBy:NeuronReach; // this neuron is connected by ...
	}
}