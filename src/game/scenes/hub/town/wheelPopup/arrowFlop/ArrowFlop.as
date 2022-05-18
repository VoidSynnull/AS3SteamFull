package game.scenes.hub.town.wheelPopup.arrowFlop
{
	import ash.core.Component;
	
	import engine.components.Spatial;
	
	import org.osflash.signals.Signal;
	
	public class ArrowFlop extends Component
	{
		public var floppage:Number;
		public var flops:Number;
		public var offset:Number;
		public var target:Spatial;
		public var flipped:Boolean;
		public var flopped:Signal;
		public function ArrowFlop(target:Spatial, floppage:Number = 5, flops:Number = 1, offset:Number = 0)
		{
			this.target = target;
			this.floppage = floppage;
			this.flops = flops;
			this.offset = offset;
		}
	}
}