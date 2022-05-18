package game.scenes.ghd.shared.fallingRocks
{
	
	import com.greensock.easing.Linear;
	
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.Emitter;
	import game.components.entity.Children;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.Bounce;
	import game.components.hit.CurrentHit;
	import game.components.hit.Platform;
	import game.components.hit.Wall;
	import game.data.motion.time.FixedTimestep;
	import game.nodes.hit.WallHitNode;
	import game.scenes.deepDive2.predatorArea.particles.GlassParticles;
	import game.scenes.ghd.shared.groundShadows.GroundShadow;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	
	public class MeteorSystem extends GameSystem
	{
		private var rockList:NodeList;
		private var player:Entity;
		
		private const ROCK_SMASH:String = SoundManager.EFFECTS_PATH + "large_stone_01.mp3";
		private const HIT_SOUND:String = SoundManager.EFFECTS_PATH + "rock_hit_03.mp3";
		private const FALL_SOUND:String = SoundManager.EFFECTS_PATH + "object_fall_01.mp3";
		
		private var wallList:NodeList;
		private var targetRadius:Number = 200; 
		
		
		public function MeteorSystem()
		{
			super(MeteorNode, nodeUpdate, nodeAdded, nodeRemoved);
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
			super._defaultPriority = SystemPriorities.resolveCollisions;
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			player = group.shellApi.player;
			rockList = systemManager.getNodeList(MeteorHitRockNode);
			wallList = systemManager.getNodeList(WallHitNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			super.removeFromEngine(systemManager);
		}
		
		public function nodeUpdate(node:MeteorNode, time:Number):void
		{	
			var rockNode:MeteorHitRockNode = rockList.head;
			
			var meteorEnt:Entity = node.entity;
			var meteor:Meteor = node.meteor;
			//var motion:Motion = node.motion;
			var spat:Spatial = node.spatial;
			var disp:Display = node.display;
			
			switch(meteor.state)
			{
				case Meteor.FALLING:
				{
					// move, check hits, respond as needed
					//motion.velocity.y = meteor.fallSpeed;
					//motion.velocity.x = meteor.xDrift;
					//motion.rotationVelocity = meteor.spinRate;
					node.hazard.active = true;
					var shad:Entity = node.child.getChildByName("shadow");
					if(shad){
						GroundShadow(shad.get(GroundShadow)).on = true;
					}
					// rocks
					var curhit:Entity = CurrentHit(meteorEnt.get(CurrentHit)).hit;
					var hitRock:Boolean = false;
					if(rockNode && curhit){
						for (rockNode = rockList.head; rockNode; rockNode = rockNode.next )
						{						
							var rock:Entity = rockNode.entity;
							var rockDisp:Display = rockNode.display;
							var child:Entity;
							// hit test
							for(var i:int = 0; i < rockNode.child.children.length; i++)
							{
								child = rockNode.child.children[i];
								//if(curhit){
								if(curhit.get(Id).id == child.get(Id).id || curhit.get(Id).id == rock.get(Id).id ){
									// hit a rock
									explode(node,rockNode);
									hitRock = true; 
									return;
								}
									//									else if(curhit.has(Bounce)){
									//										// hit jello
									//									}
									//									else{
									//										// hit anything else
									//										explode(node);
									//									}
									//}
								else if(WallCollider(meteorEnt.get(WallCollider)).isHit){
									// wall check
									hitRock = wallCheck(node,rockNode,child);
								}
							}
						}
						if(!hitRock && !curhit.has(Bounce)){
							explode(node);
						}
					}
					break;
				}
				case Meteor.EXPLODE:
				{
					//wait for particles to clear, then start reset of meteor
					updateExplode(node,time);
					break;
				}
				case Meteor.RESETTING:
				{
					// waiting over, reset meteor, drop in a bit
					meteor.respawnTimer += time;
					if(meteor.respawnTimer > meteor.respawnDelay){
						meteor.respawnTimer = 0;
						launchMeteor(node);
					}
					break;
				}
			};
			
		}
		
		private function wallCheck(node:MeteorNode, rockNode:MeteorHitRockNode, child:Entity):Boolean
		{
			var wallNode:WallHitNode = wallList.head;
			for (wallNode = wallList.head; wallNode; wallNode = wallNode.next )
			{	
				if(wallNode.id.id == child.get(Id).id){
					if(wallNode.hits.entities.indexOf("meteor") != -1){
						explode(node,rockNode);
						return true;
					}
				}
			}
			return false;
		}
		
		private function updateExplode(node:MeteorNode, time:Number):void
		{
			node.meteor.respawnTimer += time;
			if(Emitter(node.child.getChildByName("emitter").get(Emitter)).emitter.particles.length <= 0 ){
				node.meteor.respawnTimer = 0;
				node.meteor.state = Meteor.RESETTING;
			}
		}
		
		private function explode(node:MeteorNode, rockNode:MeteorHitRockNode = null):void
		{
			// reset meteor, destroy ground rock, add particles
			var meteorEnt:Entity = node.entity;
			var mChilds:Children = node.child;
			var child:Entity;
			
			//if(node.meteor.state != Meteor.EXPLODE){
			node.meteor.state = Meteor.EXPLODE;
			MotionUtils.zeroMotion(meteorEnt);
			node.display.visible = false;
			//blowup meteor
			child = mChilds.getChildByName("emitter");
			if(child.has(Emitter)){
				GlassParticles(child.get(Emitter).emitter).spark(50,160);
				AudioUtils.playSoundFromEntity(meteorEnt, ROCK_SMASH, 600, 0.35, 1.0, Linear.easeInOut);
			}
			// kill hazard
			node.hazard.active = false;
			// lock motion
			node.motion.zeroAcceleration();
			node.motion.zeroMotion();
			
			// signal rock impact
			if(node.meteor.impactSig != null){
				node.meteor.impactSig.dispatch(meteorEnt);
			}
			
			if(rockNode){
				var rockEnt:Entity = rockNode.entity;
				rockEnt.remove(Platform);
				rockEnt.remove(Wall);
				var rock:MeteorHitRock = rockNode.rock;
				var rockDisplay:Display = rockNode.display;
				
				var rockChilds:Children = rockNode.child;
				// remove wall/platforms
				for (var i:int = 0; i < rockChilds.children.length; i++) 
				{
					child = rockChilds.children[i];
					if(child.has(Wall)){
						child.remove(Wall);
					}
					else if( child.has(Platform)){
						child.remove(Platform);
					}
					else if(child.has(Emitter)){
						GlassParticles(child.get(Emitter).emitter).spark(50,160);
					}
				}
				if(rock.onHitSignal != null){
					rock.onHitSignal.dispatch(rockEnt);
				}
				rockDisplay.visible = false;
				rockNode.rock.hit = true;
				//	group.removeEntity(rockEnt,true);
			}
			//}
		}
		
		private function launchMeteor(node:MeteorNode):void
		{
			// target near player
			var meteor:Meteor = node.meteor;
			var pPos:Point = EntityUtils.getPosition(player);
			var mPos:Point = new Point();
			var mDisplay:Display = node.display;
			mDisplay.visible = true;
			meteor.state = Meteor.FALLING;
			mPos.x = GeomUtils.randomInRange(pPos.x - targetRadius*1.5, pPos.x + targetRadius*.5);
			//mPos.x = GeomUtils.randomInRange(pPos.x - 100, pPos.x + 100);
			mPos.y = pPos.y - 800; 
			EntityUtils.position(node.entity,mPos.x, mPos.y);
			//meteor.fallSpeed = 300 + GeomUtils.randomInt(-60, 60);
			node.motion.acceleration = new Point(0, meteor.fallSpeed);
			meteor.spinRate = 30 + GeomUtils.randomInt(-90, 60);
			var motion:Motion = node.motion;
			
			motion.velocity.x = meteor.xDrift;
			motion.rotationVelocity = meteor.spinRate;
			
			AudioUtils.playSoundFromEntity(node.entity, FALL_SOUND, 800, 0.50, 1.5, Linear.easeInOut);
		}
		
		public function nodeAdded(node:MeteorNode):void
		{
			//trace("meteor added")
		}
		
		public function nodeRemoved(node:MeteorNode):void
		{
			
		}
	}
}