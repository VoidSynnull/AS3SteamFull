package game.scenes.virusHunter.day2Lungs.systems 
{
	import com.greensock.easing.Quad;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.hit.MovieClipHit;
	import game.data.TimedEvent;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.day2Lungs.Day2Lungs;
	import game.scenes.virusHunter.day2Lungs.data.HoleData;
	import game.scenes.virusHunter.day2Lungs.nodes.HoleTentacleNode;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.Utils;

	public class HoleTentacleSystem extends System
	{
		private var events:VirusHunterEvents;
		private var player:Spatial;
		private var creator:EnemyCreator;
		private var numTentacles:uint;
		private var empty:Vector.<HoleData>;
		
		private var elapsedTime:Number;
		private var waitTime:Number;
		
		private var nodes:NodeList;
		
		public function HoleTentacleSystem(creator:EnemyCreator, events:VirusHunterEvents, player:Entity, numTentacles:uint)
		{
			this.creator = creator;
			this.events = events;
			this.player = player.get(Spatial);
			this.numTentacles = numTentacles;
			this.empty = new Vector.<HoleData>();
			this.elapsedTime = 0;
			this.waitTime = 7;
		}
		
		override public function update(time:Number):void
		{
			updateTentacles();
			
			/**
			 * Only update this every so many seconds.
			 * Too many Hole checks is unneccesary.
			 */
			this.elapsedTime += time;
			if(this.elapsedTime >= this.waitTime)
			{
				this.elapsedTime = 0;
				updateHoles();
			}
		}
		
		private function updateTentacles():void
		{
			for(var node:HoleTentacleNode = nodes.head; node; node = node.next)
			{
				if(EntityUtils.sleeping(node.entity)) continue;
				
				if(node.target.isHit && !node.target.isTriggered)
				{
					node.target.isHit = false;
					node.audio.play(SoundManager.EFFECTS_PATH + "tendrils_hit_0" + Utils.randInRange(1, 4) + ".mp3", false, SoundModifier.EFFECTS);
					
					if(node.target.damage >= node.target.maxDamage)
					{
						node.target.isTriggered = true;
						
						var radians:Number = GeomUtils.degreeToRadian(node.spatial.rotation);
						var x:Number = Math.cos(radians) * 400 + node.spatial.x;
						var y:Number = Math.sin(radians) * 400 + node.spatial.y;
						
						creator.createRandomPickup(x, y, false);
						creator.createRandomPickup(x, y, false);
						
						this.numTentacles--;
						if(this.numTentacles <= 0)
						{
							this.group.shellApi.completeEvent(this.events.LUNG_WORMS_DEFEATED);
							this.group.shellApi.triggerEvent(this.events.BOSS_BATTLE_ENDED);
						}
						
						/**
						 * Immediately check the locationas of all Tentacles once a Tentacle is killed.
						 * Add the dead Tentacle's data to the list of empty Holes.
						 * Set isTransitioning to true so this Tentacle isn't picked for Hole changes.
						 */
						this.empty.push(node.hole.data);
						node.hole.isTransitioning = true;
						
						/**
						 * The Tentacle is dead, so fade it out and remove the entity from the game.
						 */
						node.entity.remove(MovieClipHit);
						var object:Object = { alpha:0, onComplete:removeEntity, onCompleteParams:[node] };
						node.tween.to(node.entity.get(Display), 1, object);
					}
				}
			}
		}
		
		private function updateHoles():void
		{
			/**
			 * HoleData will be removed from empty once its been checked.
			 * It will be added to this checked list so it's not checked again.
			 */
			var checked:Vector.<HoleData> = new Vector.<HoleData>();
			
			while(empty.length > 0)
			{
				/**
				 * Get an empty Hole and calculate its distance from the player.
				 */
				var data:HoleData = this.empty.pop();
				var holeDistance:Number = Utils.distance(player.x, player.y, data.x, data.y);
				
				var distance:Number = 0;
				var tentacle:HoleTentacleNode;
				
				for(var node:HoleTentacleNode = nodes.head; node; node = node.next)
				{
					if(EntityUtils.sleeping(node.entity)) continue;
					
					/**
					 * If the Tentacle is currently transitioning to another Hole or the Tentacle is
					 * a priority Hole defending the exit, don't pick it.
					 */
					if(node.hole.isTransitioning) continue;
					if(node.hole.data.index == 4 || node.hole.data.index == 5) continue;
					
					/**
					 * If the Hole is farther away than the Tentacle, don't pick it.
					 */
					var tentacleDistance:Number = Utils.distance(player.x, player.y, node.hole.data.x, node.hole.data.y);
					if(holeDistance > tentacleDistance) continue;
					
					/**
					 * The Tentacle is farther than the previously picked Tentacle.
					 * Choose this one instead and update the farthest distance and node.
					 */
					if(tentacleDistance > distance)
					{
						distance = tentacleDistance;
						tentacle = node;
					}
				}
				
				/**
				 * If no Tentacle was deemed farther away from the player than the Hole was, or there were no changes,
				 * skip the rest of this transitioning stage and add the HoleData to checked.
				 */
				if(tentacle == null)
				{
					checked.push(data);
					continue;
				}
				
				/**
				 * Add the Tentacle's current HoleData to the empty list.
				 * Make the Tentacle's current HoleData the chosen data and remove it from the empty list.
				 */
				checked.push(tentacle.hole.data);
				tentacle.hole.data = data;
				
				/**
				 * Stop updating the Tentacle's movement updates, but keep drawing its segments.
				 * Mark this Hole as being transitioned so this Tentacle doesn't get picked for another Hole.
				 */
				tentacle.tentacle.isPaused = true;
				tentacle.hole.isTransitioning = true;
				
				/**
				 * Calculate the radians required to tween the Tentacle fully into the Hole.
				 * Gets the Spatial x and y location of a fully hidden Tentacle.
				 */
				var radians:Number = GeomUtils.degreeToRadian(tentacle.spatial.rotation + 180);
				var x:Number = tentacle.spatial.x + 1500 * Math.cos(radians);
				var y:Number = tentacle.spatial.y + 1500 * Math.sin(radians);
				
				/**
				 * Tween into Hole. Also tween the Tentacles segments into a straight
				 * line so it'll fit into the Hole as it moves.
				 */
				var object:Object = { x:x, y:y, ease:Quad.easeInOut, onComplete:moveIntoHole, onCompleteParams:[tentacle] };
				tentacle.tween.to(tentacle.spatial, 2, object);
				
				for(var u:uint = 0; u < tentacle.tentacle.segments.size; u++)
				{
					object = { x:(u * tentacle.tentacle.getSegmentLength()), y:0, ease:Quad.easeInOut };
					tentacle.tween.to(tentacle.tentacle.segments.itemAt(u), 0.8, object); 
				}
			}
			
			/**
			 * After all Hole checks, take all the checked Holes and put them back into the empty list.
			 */
			while(checked.length > 0)
				this.empty.push(checked.pop());
		}
		
		private function moveIntoHole(node:HoleTentacleNode):void
		{
			/**
			 * Set the node's Tentacle component based on its HoleData. Some holes have
			 * a change in size and speed, such as the two Tentacles guarding the exit.
			 */
			node.tentacle.setNumSegments(node.hole.data.numSegments);
			node.tentacle.minDistance 	= node.hole.data.minDistance;
			node.tentacle.maxDistance 	= node.hole.data.maxDistance;
			node.tentacle.minSpeed 		= node.hole.data.minSpeed;
			node.tentacle.maxSpeed 		= node.hole.data.maxSpeed;
			node.tentacle.minMagnitude 	= node.hole.data.minMagnitude;
			node.tentacle.maxMagnitude 	= node.hole.data.maxMagnitude;
			node.tentacle.isPaused 		= true;
			
			/**
			 * Position the Tentacle at a distance far enough away from the empty Hole where it can't
			 * be seen. This is based on the HoleData's rotation, but 180 degrees in the other direction.
			 */
			node.spatial.rotation = node.hole.data.rotation;
			var radians:Number = GeomUtils.degreeToRadian(node.spatial.rotation + 180);
			node.spatial.x = node.hole.data.x + (1500 * Math.cos(radians));
			node.spatial.y = node.hole.data.y + (1500 * Math.sin(radians));
			
			/**
			 * Tween the Tentacle into its new Ho9le. Once it's complete, set isTransitioning
			 * to false so it can be transitioned later.
			 */
			var object:Object = { x:node.hole.data.x, y:node.hole.data.y, ease:Quad.easeInOut, onComplete:unpauseTentacle, onCompleteParams:[node] };
			node.tween.to(node.spatial, 1, object); 
		}
		
		private function unpauseTentacle(node:HoleTentacleNode):void
		{
			node.tentacle.time = 0;
			node.tentacle.isPaused = false;
			node.hole.isTransitioning = false;
		}
		
		private function removeEntity(node:HoleTentacleNode):void
		{
			this.group.removeEntity(node.entity);
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			this.nodes = systemManager.getNodeList(HoleTentacleNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(HoleTentacleNode);
			this.nodes = null;
		}
	}
}