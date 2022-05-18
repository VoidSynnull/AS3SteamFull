package game.scenes.arab1.shared.systems
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scene.template.GameScene;
	import game.scenes.arab1.shared.components.SandScorpion;
	import game.scenes.arab1.shared.nodes.SandScorpionNode;
	import game.scenes.arab1.shared.particles.Sand;
	import game.systems.GameSystem;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	
	public class SandScorpionSystem extends GameSystem
	{
		private var player:Entity;
		private var playerSpatial:Spatial;
		
		private var _sandParticles:Sand;
		private var _sandParticleEmitter:Entity;
		
		public const DIG_SOUND:String = SoundManager.EFFECTS_PATH + "sand_bag_01.mp3";
		public const MOVE_SOUND:String = SoundManager.EFFECTS_PATH + "insect_scurry_01.mp3";
		
		public function SandScorpionSystem()
		{
			super(SandScorpionNode, nodeUpdate, nodeAdded);
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			player = group.shellApi.player;
			playerSpatial = player.get(Spatial);
			super.addToEngine(systemManager);
		}
		
		public function nodeAdded(node:SandScorpionNode):void
		{
			// plant the signals
			node.scorpion.zone.entered.removeAll();
			node.scorpion.zone.entered.addOnce(Command.create(appearP1,node));
			node.scorpion.scale = node.spatial.scaleX;
			node.timeline.gotoAndStop("hideEnd");
			node.scorpion.hazard.active = false;
			node.scorpion.hidden = true;
		}
		
		public function nodeUpdate(node:SandScorpionNode, time:Number=0):void
		{
			var scorpion:SandScorpion = node.scorpion;
			if(scorpion.enabled){
				
			}
		}

		public function appearP1(z:String, i:String, node:SandScorpionNode):void
		{
			SceneUtil.addTimedEvent(group,new TimedEvent(.25,1,Command.create(appearP2,node)),"scorpTimer");
		}
		
		public function appearP2( node:SandScorpionNode):void
		{
			if(node.scorpion.hidden){
				// pick spot under player's feet! surpize!
				var targ:Point = EntityUtils.getPosition(node.entity);
				var xShift:Number = GeomUtils.randomInRange(-100,100);
				targ.x = playerSpatial.x + xShift;
				EntityUtils.position(node.entity, targ.x, targ.y);
				if(targ.x < playerSpatial.x){
					// face right
					node.spatial.scaleX = node.scorpion.scale;
				}
				else{ 
					// face left	
					node.spatial.scaleX = -node.scorpion.scale;
				}
				// emit particles and then emerge
				startSandParticles(node);
				SceneUtil.addTimedEvent(group,new TimedEvent(0.5,1,Command.create(appear,node)));
			}
		}
		
		private function appear(node:SandScorpionNode):void
		{
			node.timeline.gotoAndPlay("appear");
			node.timeline.handleLabel("appearEnd",Command.create(appeared,node));
			node.scorpion.hazard.active = true;
			AudioUtils.play(group,DIG_SOUND,0.8);
		}
		
		public function appeared(node:SandScorpionNode, ...p):void
		{
			// move
			stopSandParticles();
			node.motion.velocity.x = node.scorpion.speed * node.spatial.scaleX;
			node.scorpion.zone.entered.addOnce(Command.create(appearP1,node));
			node.timeline.gotoAndPlay("walk");
			SceneUtil.addTimedEvent(group,new TimedEvent(node.scorpion.delay,1,Command.create(hide,node)),"scorpTimer");
			AudioUtils.play(group,MOVE_SOUND,0.7);
			node.scorpion.hidden = false;
		}
		
		public function hide(node:SandScorpionNode):void
		{
			// stop
			stopSandParticles();
			node.motion.velocity.x = 0;
			if(!node.scorpion.hidden){
				node.timeline.gotoAndPlay("hide");
				node.timeline.handleLabel("hideEnd",Command.create(hidden,node));
				node.scorpion.hazard.active = false;
				AudioUtils.play(group,DIG_SOUND,0.7);
			}
			AudioUtils.stop(group,MOVE_SOUND);
		}
		
		public function hidden(node:SandScorpionNode, ...p):void
		{
			node.scorpion.hidden = true;
			node.scorpion.zone.entered.removeAll();
			node.scorpion.zone.entered.addOnce(Command.create(appearP1,node));
		}
		

		private function stopSandParticles():void
		{
			if(_sandParticles){
				_sandParticles.counter.stop();
			}
		}
		
		private function startSandParticles(node:SandScorpionNode):void
		{
			_sandParticles = new Sand();
			_sandParticles.init(0x775220);
			_sandParticleEmitter = EmitterCreator.create(group, GameScene(group).hitContainer, _sandParticles, 0, 0, null, "sand", node.spatial,true);
		}
		
		
		
		
		
		
		
		
		
	}
}