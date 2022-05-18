package game.scenes.arab1.shared.systems
{	
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.hit.CurrentHit;
	import game.components.hit.Platform;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scenes.arab1.shared.components.QuickSand;
	import game.scenes.arab1.shared.nodes.QuickSandNode;
	import game.scenes.arab1.shared.particles.Sand;
	import game.systems.GameSystem;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class QuickSandSystem extends GameSystem
	{
		private var player:Entity;
		private var currHit:CurrentHit;
		
		private var SINK_SOUND:String = SoundManager.EFFECTS_PATH+"drag_rope_01_loop.mp3";
		
		private var _sandParticles:Sand;
		private var _sandParticleEmitter:Entity;
		
		public function QuickSandSystem()
		{
			super(QuickSandNode, updateNode);
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			player = group.shellApi.player;
			currHit = player.get(CurrentHit);
			super.addToEngine(systemManager);
		}
		
		private function updateNode(node:QuickSandNode, time:Number = 0):void
		{
			var sandEnt:Entity = node.entity;
			var sand:QuickSand = node.quickSand;
			var motion:Motion = node.motion;
			var spatial:Spatial = node.spatial;
			
			if(!sand.fallThru){
				// run these until fallthru point is reached, then drop player and reset sand
				if(!sand.sinking){
					// check for sinking
					if(currHit.hit && currHit.hit.get(Id).id == node.id.id){
						motion.velocity.y = sand.sinkSpeed;
						AudioUtils.play(group, SINK_SOUND);
						sand.sinking = true;
						startSandParticles(node);
					}else{
						resetNode(node);
					}
				}
				else{
					// sink
					if(spatial.y > sand.startingPoint.y + sand.depth){
						// stop sink, drop player
						motion.velocity.y = 0;
						sand.sinking = false;
						AudioUtils.stop(group, SINK_SOUND);
						sand.fallThru = true;
						stopSandParticles();
					}
				}
			}
			else{
				sandEnt.remove(Platform);
			}
			// reset when player not hitting
			if(currHit.hit == null || currHit.hit.get(Id).id != node.id.id){
				resetNode(node);
			}
				
		}
		
		private function resetNode(node:QuickSandNode):void
		{
			if(node.quickSand.fallThru || node.quickSand.sinking){
				node.motion.velocity.y = 0;
				var startingPoint:Point = node.quickSand.startingPoint;
				SceneUtil.addTimedEvent(group, new TimedEvent(.1,1,Command.create(EntityUtils.position,node.entity,startingPoint.x,startingPoint.y)),"sink");
				node.entity.add(new Platform());
				node.quickSand.fallThru = false;
				node.quickSand.sinking = false;
				stopSandParticles();
				AudioUtils.stop(group, SINK_SOUND);
			}
		}
		
		private function stopSandParticles():void
		{
			if(_sandParticles){
				_sandParticles.counter.stop();
			}
		}
		
		private function startSandParticles(node:QuickSandNode):void
		{
			if(!_sandParticleEmitter){
				_sandParticles = new Sand();
				_sandParticles.init();
				_sandParticleEmitter = EmitterCreator.create(group, Display(node.entity.get(Display)).container, _sandParticles, 0, 0, node.entity, "sand", player.get(Spatial),true);
			}else{
				_sandParticles.counter.resume();
			}
		}
		
		
		
		
		
		
		
		
		
		
		
		
	}
}