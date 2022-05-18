package game.scenes.deepDive3.cargoBay.systems 
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.deepDive2.medusaArea.MedusaArea;
	import game.scenes.deepDive3.cargoBay.CargoBay;
	import game.scenes.deepDive3.cargoBay.nodes.DroneTargetNode;
	import game.systems.SystemPriorities;
	
	public class DroneTargetSystem extends System
	{
		private var _droneTargets:NodeList;
		private var player:Entity;
		private var pSpatial:Spatial;
		
		private var radius:Number = 277;
		private var degrees:Number = 0;
		private var angle:Number = 0;
		
		private var dx:Number = 0;
		private var dy:Number = 0;
		private var dist:Number = 0;
		
		private var teleX:Number = 696;
		private var teleY:Number = 598;
		
		public function DroneTargetSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_droneTargets = systemManager.getNodeList( DroneTargetNode );
			player = CargoBay(super.group).player;
			pSpatial = CargoBay(super.group).player.get(Spatial);
		}
		
		override public function update( time:Number ):void
		{
			var droneTarget:DroneTargetNode;
			
			for(droneTarget = _droneTargets.head; droneTarget; droneTarget = droneTarget.next) {
				
				dx = pSpatial.x - teleX;
				dy = pSpatial.y - teleY;
				degrees = (Math.atan2(dy, dx) * 180 / Math.PI) + droneTarget.droneTarget.angle;
				
				angle = degrees * (Math.PI/180);
				
				droneTarget.spatial.x = radius * Math.cos(angle) + teleX;
				droneTarget.spatial.y = radius * Math.sin(angle) + teleY;
			}
			
			//hit test
			
			dx = teleX - pSpatial.x;
			dy = teleY - pSpatial.y;
			dist = Math.sqrt(dx * dx + dy * dy);
			
			if(dist < 400){
				CargoBay(super.group).doorStop();
			}
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( DroneTargetNode );
			_droneTargets = null;
		}
	}
}




