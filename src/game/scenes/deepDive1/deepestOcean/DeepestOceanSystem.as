package game.scenes.deepDive1.deepestOcean 
{
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.Utils;
	
	public class DeepestOceanSystem extends System
	{
		private var player:Entity;
		private var playerSpatial:Spatial;
		private var playerSpatialAddition:SpatialAddition;
		private var playerMotion:Motion;
		
		private var finalSequenceStarted:Boolean = false;
		
		public function DeepestOceanSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			player = DeepestOcean(super.group).shellApi.player;
			playerSpatial = DeepestOcean(super.group).shellApi.player.get(Spatial);
			playerSpatialAddition = DeepestOcean(super.group).shellApi.player.get(SpatialAddition);
			playerMotion = DeepestOcean(super.group).shellApi.player.get(Motion);
		}
		
		override public function update( time:Number ):void
		{			
			if(playerMotion.velocity.x > 0){
				if(playerSpatial.scaleX > 0){
					CharUtils.setDirection(player, true);
				}
				playerSpatialAddition.rotation = Utils.randNumInRange(0, 3);
			}else if(playerMotion.velocity.x < 0){
				if(playerSpatial.scaleX < 0){
					CharUtils.setDirection(player, false);
				}
				playerSpatialAddition.rotation = Utils.randNumInRange(0, 3);
			}else{
				playerSpatialAddition.rotation = 0;
			}
			
			if(!finalSequenceStarted){
				if(playerSpatial.x > 910){
					finalSequenceStarted = true;
					DeepestOcean(super.group).startFinalSequence();
				}
			}
		}
				
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			//systemsManager.releaseNodeList( BallNode );
			//_balls = null;
		}
	}
}




