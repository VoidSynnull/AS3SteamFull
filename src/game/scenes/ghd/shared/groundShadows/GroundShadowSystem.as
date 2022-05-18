package game.scenes.ghd.shared.groundShadows
{	
	import ash.core.Engine;
	
	import engine.components.Spatial;
	
	import game.data.motion.time.FixedTimestep;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	
	public class GroundShadowSystem extends GameSystem
	{
		//private var _hitAreaNodes:NodeList;
		//private var _hitAreaNode:BitmapHitAreaNode;
		//public const colors:Array = [0x00ff00,0x003300,0x009900,0x006600,0x00cc00,0x00ff66,0x00cc66,0x009966];
		
		public function GroundShadowSystem()
		{
			super(GroundShadowNode, nodeUpdate, nodeAdded, nodeRemoved);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.resolveCollisions;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			//_hitAreaNodes = systemManager.getNodeList(BitmapHitAreaNode);
			//_hitAreaNode = _hitAreaNodes.head;
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			super.removeFromEngine(systemManager);
		}
		
		public function nodeUpdate(node:GroundShadowNode, time:Number):void
		{	
			var shadow:GroundShadow = node.shadow;
			var spatial:Spatial = node.spatial;
			var targetSpat:Spatial = node.follow.target;
			
			if(shadow.on){
				node.display.visible = true;
				// find top most platform pos on shadow's x position
				// set shadow y to platform y value at that x location
				/*				var hitAreaBmp:BitmapData = _hitAreaNode.bitmapHitArea.bitmapData;
				for (var i:int = node.display.displayObject.y; i < group.shellApi.currentScene.sceneData.cameraLimits.bottom; i++) 
				{
				var color:uint = hitAreaBmp.getPixel(node.display.displayObject.x,i);
				if(colors.indexOf(color) != -1){
				var offset:Number = i //+ group.shellApi.offsetY(i);
				//if(spatial.y != offset){
				spatial.y = offset;
				//}
				
				break;
				}
				}	*/
				// scale based on distance from follow target
				var dist:Number = GeomUtils.dist(spatial.x, spatial.y, targetSpat.x, targetSpat.y);
				if(dist > 100 && targetSpat.y < spatial.y){
					var newScale:Number = shadow.scaleMultiplyer / Math.sqrt(dist);
					if(newScale< shadow.scaleMin){
						newScale = shadow.scaleMin;
					}else if(newScale > shadow.scaleMax){
						newScale = shadow.scaleMax;
					}
					shadow.scaleCurrent = newScale;
					spatial.scale = shadow.scaleCurrent;
				}else{
					shadow.on = false;
					node.display.visible = false;
				}
			}
			else{
				node.display.visible = false;
			}
			
		}
		
		public function nodeAdded(node:GroundShadowNode):void
		{
			//trace("shadow added")
		}
		
		public function nodeRemoved(node:GroundShadowNode):void
		{
			
		}
	}
}