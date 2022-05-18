package game.scenes.shrink.bedroomShrunk02.SideFanSystem
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.nodes.RenderNode;
	
	public class SideFan extends Component
	{
		public var sideViewOfBlades:Vector.<RenderNode>;
		public var topViewOfBlades:Vector.<RenderNode>;
		public var rotation:Number;
		public var focalRadius:Number;
		public var bladeLength:Number;
		public var maxFanSpeed:Number;
		public var acc:Number;
		public var speed:Number;
		public var dampening:Number;
		public var on:Boolean;
		
		public function SideFan(focalRadius:Number = 50, bladeLength:Number = 200, maxFanSpeed:Number = 360, acc:Number = 10, dampening:Number = .95, startOn:Boolean = true)
		{
			this.focalRadius = focalRadius;
			this.bladeLength = bladeLength;
			this.maxFanSpeed = maxFanSpeed;
			this.acc = acc;
			this.dampening = dampening;
			
			sideViewOfBlades = new Vector.<RenderNode>();
			topViewOfBlades = new Vector.<RenderNode>();
			
			on = startOn;
			speed = 0;
			rotation = 0;
		}
		
		public function addBlade(side:Entity, top:Entity):void
		{
			var renderNode:RenderNode = new RenderNode();
			renderNode.entity = side;
			renderNode.display = side.get(Display);
			renderNode.spatial = side.get(Spatial);
			sideViewOfBlades.push(renderNode);
			
			renderNode = new RenderNode();
			renderNode.entity = top;
			renderNode.display = top.get(Display);
			renderNode.spatial = top.get(Spatial);
			topViewOfBlades.push(renderNode);
		}
	}
}