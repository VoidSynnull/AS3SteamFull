package game.scenes.carnival.tunnelLove.systems
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.collider.PlatformCollider;
	import game.data.animation.entity.character.Grief;
	import game.scenes.carnival.CarnivalEvents;
	import game.scenes.carnival.tunnelLove.TunnelLove;
	import game.scenes.carnival.tunnelLove.nodes.BoatNode;
	
	public class BoatSystem extends ListIteratingSystem
	{
		public function BoatSystem($container:DisplayObjectContainer, $group:TunnelLove, $events:CarnivalEvents)
		{
			_sceneGroup = $group;
			_container = $container;
			_events = $events;
			super(BoatNode, onUpdate);
		}
		
		private function onUpdate($node:BoatNode, $time:Number):void{
			var boatSpatial:Spatial = $node.boat.boatEntity.get(Spatial);
			
			var boatMotion:Motion = $node.boat.boatEntity.get(Motion);
			var platMotion:Motion = $node.boat.platformEntity.get(Motion);
			//var ripplesMotion:Motion = $node.boat.ripples.get(Motion);
			
			// move beads if within beads' space
			if(boatSpatial.x >= 183 && boatSpatial.x < 275){
				_sceneGroup.moveBeads();
			} else if(boatSpatial.x >= 3312 && boatSpatial.x < 3400){
				_sceneGroup.moveBeads(true);
			}
			
			// detect where player is on the boat and start and stop depending...
			var platformCol:PlatformCollider = _sceneGroup.player.get(PlatformCollider);
			var playerSpatial:Spatial = _sceneGroup.player.get(Spatial);
			
			/*
			
			if(platformCol.isHit == true && playerSpatial.y == 736.95){
				// if player on boat, speed up boat
				boatMotion.acceleration = new Point(10,0);
				platMotion.acceleration = new Point(10,0);
			} else {
				// if player not on boat, slow down boat
				if(boatMotion.velocity.x >= 0){
					boatMotion.acceleration = new Point(-10,0);
					platMotion.acceleration = new Point(-10,0);
				} else {
					boatMotion.acceleration.x = 0;
					platMotion.acceleration.x = 0;
					boatMotion.velocity.x = 0;
					platMotion.velocity.x = 0;
				}
			}*/
			
			// stop boat by teens boat if present
			if(_sceneGroup.shellApi.checkEvent(_events.TEENS_IN_TUNNEL) && !_sceneGroup.shellApi.checkEvent(_events.TEENS_FRIGHTENED)){
				if(boatSpatial.x >= 1900){
					_sceneGroup.fadeOutBoatSound();
					if(boatMotion.velocity.x > 0){
						boatMotion.acceleration = new Point(-20,0);
						platMotion.acceleration = new Point(-20,0);
						//ripplesMotion.acceleration = new Point(-20,0);
						
						// prevent reverse direction
						if(boatMotion.velocity.x < 0){
							boatMotion.acceleration.x = 0;
							platMotion.acceleration.x = 0;
							//ripplesMotion.acceleration.x = 0;
							boatMotion.velocity.x = 0;
							platMotion.velocity.x = 0;
							//ripplesMotion.velocity.x = 0;
						}
						
					} else {
						boatMotion.acceleration.x = 0;
						platMotion.acceleration.x = 0;
						//ripplesMotion.acceleration.x = 0;
						boatMotion.velocity.x = 0;
						platMotion.velocity.x = 0;
						//ripplesMotion.velocity.x = 0;
					}
				}
			}
			
			
			// if player hits water, reset ignoreNextHit
			if(platformCol.ignoreNextHit == true && platformCol.baseGround == true){
				platformCol.ignoreNextHit = false;
			}
			
			if(platformCol.baseGround == true){
				_sceneGroup.fellInWater();
			}
		}
		
		private var _sceneGroup:TunnelLove;
		private var _container:DisplayObjectContainer;
		private var _events:CarnivalEvents;
	}
}