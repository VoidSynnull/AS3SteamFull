package game.scenes.virusHunter.lungs.systems 
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.systems.CameraSystem;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.joesCondo.JoesCondo;
	import game.scenes.virusHunter.lungs.Lungs;
	import game.scenes.virusHunter.lungs.components.BossArm;
	import game.scenes.virusHunter.lungs.components.BossClaw;
	import game.scenes.virusHunter.lungs.components.BossHead;
	import game.scenes.virusHunter.lungs.components.BossState;
	import game.scenes.virusHunter.lungs.nodes.BossNode;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.Utils;

	public class BossSystem extends ListIteratingSystem
	{
		private var elapsedTime:Number;
		private var waitTime:Number;
		private var events:VirusHunterEvents;
		private var scene:Lungs;
		
		public function BossSystem(scene:Lungs, events:VirusHunterEvents) 
		{
			super(BossNode, updateNode);
			
			this.elapsedTime = 0;
			this.waitTime = Utils.randNumInRange(5, 10);
			this.events = events;
			this.scene = scene;
		}
		
		private function updateNode(node:BossNode, time:Number):void
		{
			var state:BossState = node.state;
			var boss:Entity = node.entity;
			
			var spatial:Spatial = boss.get(Spatial);
			var motion:Motion = boss.get(Motion);
			
			switch(state.state)
			{
				case BossState.NO_STATE:
					//Placeholder
					break;
				
				case BossState.INTRO_STATE:
					if(isStateChange(state, time, 5, BossState.IDLE_STATE))
					{
						this.scene.joeHealth.get(Display).visible = true;
						
						SceneUtil.lockInput(this.group, false, false);
						CharUtils.lockControls(this.group.shellApi.player, false, false);
						
						var camera:CameraSystem = this.group.getSystem(CameraSystem) as CameraSystem;
						camera.target = this.group.shellApi.player.get(Spatial);
						camera.rate = 0.2;
						
						for(var j:uint = 1; j <= 4; j++)
						{
							
							var claw:Entity = this.group.getEntityById("claw" + j);
							claw.get(BossClaw).isActive = false;
							var clawSpatial:Spatial = claw.get(Spatial);
							clawSpatial.x = -3;
							clawSpatial.y = -267;
							clawSpatial.rotation = 0;
							
							for(var i:uint = 1; i <= 6; i++)
							{
								var segment:Entity = this.group.getEntityById("segment" + j + i);
								
								var display:DisplayObjectContainer = Display(segment.get(Display)).displayObject;
								Display(segment.get(Display)).container.setChildIndex(display, 1);
									
								segment.get(BossArm).isActive = false;
								segment.get(Sleep).sleeping = true;
							}
						}
					}
					break;
				
				case BossState.IDLE_STATE:
					var point:Point = new Point();
					switch(state.currentLung)
					{
						case BossState.LUNG_LEFT: //Center Left (1350, 3200)
							point.x = Utils.randInRange(750, 1950);
							point.y = Utils.randInRange(2600, 3800);
							// wrb - switched to MotionUtils as the boss doesn't need collisions and char stuff
							MotionUtils.followPath(node.entity, new <Point> [point], Command.create(handleIdleMove, node), true, false, new Point(200, 200));
						break;
							
						case BossState.LUNG_RIGHT: //Center Right (4250, 3200)
							point.x = Utils.randInRange(3650, 4850);
							point.y = Utils.randInRange(2600, 3800);
							MotionUtils.followPath(node.entity, new <Point> [point], Command.create(handleIdleMove, node), true, false, new Point(200, 200));
						break;
					}
					state.state = BossState.IDLE_MOVE_STATE;
					break;
				
				case BossState.IDLE_MOVE_STATE:
					//Placeholder
					break;
				
				case BossState.ATTACK_MOVE_STATE:
					//Placeholder
					break;
				
				case BossState.ATTACK_STATE:
					//Placeholder
					break;
				
				case BossState.HURT_STATE:
					if(state.remainingSides.size > 0)
					{
						switch(state.currentLung)
						{
							case BossState.LUNG_LEFT:
								state.currentLung = BossState.LUNG_RIGHT;
								
								MotionUtils.followPath(node.entity, state.pathToRight, Command.create(handleRetreat, state), true, false, new Point(200, 200));
							break;
							
							case BossState.LUNG_RIGHT:
								state.currentLung = BossState.LUNG_LEFT;
								
								MotionUtils.followPath(node.entity, state.pathToLeft, Command.create(handleRetreat, state), true, false, new Point(200, 200));
							break;
						}
						state.state = BossState.RETREAT_STATE;
					}
					else
					{
						var timeline:Timeline;
						
						var bossHead:BossHead = this.group.getEntityById("head").get(BossHead);
						bossHead.damage.get(Display).visible = true;
						bossHead.damage.get(Timeline).gotoAndPlay("start");
						timeline = bossHead.crack.get(Timeline);
						timeline.gotoAndPlay("start");
						timeline.handleLabel("cracked", handleAudio);
						timeline.handleLabel("end", fadeToWhite);
						
						var enemySpawn:EnemySpawn = boss.get(EnemySpawn);
						enemySpawn.rate = 0;
						enemySpawn.max = 0;
						
						for(var x:uint = 1; x <= 4; x++)
						{
							var arm:Entity = this.group.getEntityById("arm" + x + "damage");
							arm.get(Display).visible = true;
							
							timeline = arm.get(Timeline);
							timeline.gotoAndPlay("start");
						}
						
						this.group.shellApi.triggerEvent(this.events.LUNG_BOSS_DEFEATED, true);
						this.scene.shipGroup.createWhiteBloodCellSwarm(node.spatial);
						this.scene.playMessage("sample_taken", false, null, null);
						
						state.state = BossState.DEAD_STATE;
					}
				break;
				
				case BossState.RETREAT_STATE:
					//Placeholder
				break;
				
				case BossState.DEAD_STATE:
					var head:Entity = this.group.getEntityById("head");
					head.get(Spatial).scale += 0.06 * time;
					BossHead(head.get(BossHead)).damage.get(Spatial).scale += 0.06 * time;
					BossHead(head.get(BossHead)).crack.get(Spatial).scale += 0.06 * time;
				break;
			}
		}
		
		private function isStateChange(state:BossState, time:Number, waitTime, nextState:String):Boolean
		{
			this.elapsedTime += time;
			if(this.elapsedTime >= waitTime)
			{
				this.elapsedTime = 0;
				state.state = nextState;
				return true;
			}
			return false;
		}
		
		private function handleAudio():void
		{
			var audio:Audio = this.group.shellApi.player.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "lungs_boss_death.mp3");
		}
		
		private function handleIdleMove(boss:Entity, node:BossNode):void
		{
			var state:BossState = node.state;
			if(Math.random() > 0.5) state.state = BossState.IDLE_STATE;
			else
			{
				switch(state.currentLung)
				{
					case BossState.LUNG_LEFT:
						state.alveoli = this.group.getEntityById("alveolus" + Utils.randInRange(1, 3));
						break;
					
					case BossState.LUNG_RIGHT:
						state.alveoli = this.group.getEntityById("alveolus" + Utils.randInRange(4, 6));
						break;
				}
				var alveoli:Spatial = state.alveoli.get(Spatial);
				state.target = new Point(alveoli.x + alveoli.width/2, alveoli.y + alveoli.height/2);
				
				var point:Point = new Point();
				var id:String = state.alveoli.get(Id).id;
				var num:uint = uint(id.charAt(id.length - 1));
				switch(num)
				{
					case 1: point.x = 1225; 	point.y = 1700;		break;
					case 2: point.x = 1900; 	point.y = 3200;		break;
					case 3: point.x = 850; 		point.y = 3950; 	break;
					case 4: point.x = 4325; 	point.y = 1700; 	break;
					case 5: point.x = 3800; 	point.y = 3200; 	break;
					case 6: point.x = 4850; 	point.y = 3950; 	break;
				}
				
				MotionUtils.followPath(node.entity, new <Point> [point], Command.create(handleAttackMove, state), true, false, new Point(200, 200));

				state.currentIndex = state.remainingSides.itemAt(Utils.randInRange(0, state.remainingSides.size-1));
				
				for(var i:uint = 1; i <= 6; i++)
					this.group.getEntityById("segment" + (state.currentIndex+1) + i).get(Sleep).sleeping = false;
				
				state.state = BossState.ATTACK_MOVE_STATE;
			}
		}
		
		private function handleAttackMove(boss:Entity, state:BossState):void
		{
			state.state = BossState.ATTACK_STATE;
			
			BossClaw(this.group.getEntityById("claw" + (state.currentIndex + 1)).get(BossClaw)).isActive = true;
			
			for(var i:uint = 1; i <= 6; i++)
			{
				var segment:Entity = this.group.getEntityById("segment" + (state.currentIndex+1) + i);
				if(segment)
				{
					var display:DisplayObjectContainer = Display(segment.get(Display)).displayObject;
					Display(segment.get(Display)).container.setChildIndex(display, 1);
					
					segment.get(BossArm).isActive = true;
					segment.get(Sleep).sleeping = false;
				}
			}
		}
		
		private function handleRetreat(entity:Entity, state:BossState):void
		{
			state.state = BossState.IDLE_STATE;
		}
		
		private function fadeToWhite():void
		{
			var explosion:Sprite = Lungs(this.group).explosion;
			var tween:Tween = new Tween();
			tween.to(explosion, 0.3, { alpha:1, ease:Quad.easeOut, onComplete:fadeFromWhite, onCompleteParams:[tween, explosion] });
			this.group.shellApi.player.add(tween);
		}
		
		private function fadeFromWhite(tween:Tween, explosion:Sprite):void
		{
			this.group.shellApi.triggerEvent(this.events.BOSS_BATTLE_ENDED);
			this.scene.shipGroup.whiteBloodCellExit();
			this.group.removeEntity(this.group.getEntityById("boss"));
			this.group.getEntityById("doorHeart").get(Sleep).sleeping = false;
			this.group.getEntityById("doorJoesCondo").get(Sleep).sleeping = false;
			tween.to(explosion, 1, { alpha:0, ease:Quad.easeIn, onComplete:handleSneeze});
		}
		
		private function handleSneeze():void
		{
			this.scene.playMessage("sneeze", false, null, null, handleLoadScene);
		}
		
		private function handleLoadScene():void
		{
			this.group.shellApi.loadScene(JoesCondo);
		}
	}
}