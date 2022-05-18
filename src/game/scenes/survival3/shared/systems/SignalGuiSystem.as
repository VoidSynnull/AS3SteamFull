package game.scenes.survival3.shared.systems
{
	import game.scenes.survival3.shared.nodes.SignalGuiNode;
	import game.systems.GameSystem;
	
	public class SignalGuiSystem extends GameSystem
	{
		public function SignalGuiSystem()
		{
			super(SignalGuiNode, updateNode);
			super.fixedTimestep = .5;
		}
		
		public function updateNode(node:SignalGuiNode, time:Number):void
		{
			var variant:Number = 0;
			if(!node.signal.signal.hasGoodSignal)
				variant = node.signal.varyRange;
			
			var frame:int = int( Math.ceil((1 - node.signal.signal.signalStrength) * node.signal.bars + variant * Math.random()));
			
			if(frame >= node.timeline.data.duration)
				frame = node.timeline.data.duration - 1;
			if(frame != node.timeline.currentIndex)
				node.timeline.gotoAndStop(frame);
		}
	}
}