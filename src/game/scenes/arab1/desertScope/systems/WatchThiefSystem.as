package game.scenes.arab1.desertScope.systems
{
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Spatial;
	
	import game.components.motion.TargetSpatial;
	import game.scenes.arab1.desertScope.nodes.WatchThiefNode;
	
	public class WatchThiefSystem extends ListIteratingSystem
	{
		private var _cameraTarget:TargetSpatial;
		private var _spottedHandler:Function;
		
		public function WatchThiefSystem( camera:Entity, handler:Function )
		{
			_cameraTarget = camera.get( TargetSpatial );
			_spottedHandler = handler;
			super(WatchThiefNode, updateNode);
		}
		
		private function updateNode($node:WatchThiefNode, $time:Number):void
		{
	//		var targetSpatial:TargetSpatial = _scene.getEntityById("camera").get(TargetSpatial);
			var spatial:Spatial = $node.entity.get(Spatial);
			
			if( distanceBetween( _cameraTarget.target, spatial) < 200 )
			{
				_spottedHandler();
			}
		}
		
		private function distanceBetween( $spatial1:Spatial, $spatial2:Spatial ):Number
		{
			return Math.sqrt(Math.pow(($spatial1.x - $spatial2.x),2) + Math.pow(($spatial1.y - $spatial2.y),2));
		}
	}
}