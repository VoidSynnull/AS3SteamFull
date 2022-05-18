package game.scenes.myth.poseidonWater.systems
{
	import com.greensock.easing.Bounce;
	
	import ash.core.Engine;
	
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.scenes.myth.poseidonWater.components.Barnicle;
	import game.scenes.myth.poseidonWater.nodes.BarnicleNode;
	import game.systems.GameSystem;
	import game.util.GeomUtils;
	
	public class BarnicleSystem extends GameSystem
	{
		public function BarnicleSystem()
		{
			super(BarnicleNode, updateNode);
		}
		
		public function updateNode(node:BarnicleNode, time:Number):void
		{
			var barnicle:Barnicle = node.barnicle;
			var barnicleSpatial:Spatial = node.spatial;
			var tween:Tween = node.tween;
			var tDuration:Number = 0.4;
			
			var r:Number = GeomUtils.spatialDistance(playerSpatial,barnicleSpatial);
			if(!barnicle.isTweening) 
			{
				if (r < barnicle.triggerRadius) 
				{
					tween.to(barnicleSpatial, tDuration,{scaleX:barnicle.startScaleX/8, scaleY:barnicle.startScaleY/8, ease:Bounce.easeInOut, onComplete:tweenFinished, onCompleteParams:[ barnicle ]});
					barnicle.isTweening = true;
				}
				else
				{
					tween.to(barnicleSpatial, tDuration,{scaleX:barnicle.startScaleX, scaleY:barnicle.startScaleY, ease:Bounce.easeInOut, onComplete:tweenFinished, onCompleteParams:[ barnicle ]});
					barnicle.isTweening = true;
				}
			}			
		}
		private function tweenFinished( barnicle:Barnicle ):void
		{
			barnicle.isTweening = false;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{			
			playerSpatial= group.shellApi.player.get( Spatial );
			super.addToEngine( systemManager );
		}		
		
		private var playerSpatial:Spatial;
	}
}
