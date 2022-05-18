package game.scenes.virusHunter.day2Heart.systems 
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.components.motion.FollowTarget;
	import game.components.entity.Sleep;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Hazard;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.day2Heart.components.WormBoss;
	import game.scenes.virusHunter.day2Heart.components.WormMass;
	import game.scenes.virusHunter.day2Heart.components.WormTentacle;
	import game.scenes.virusHunter.day2Heart.nodes.WormMassNode;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.Tentacle;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.data.WeaponType;
	import game.util.EntityUtils;
	import game.util.Utils;

	public class WormMassSystem extends ListIteratingSystem
	{
		private var state:String;
		private var elapsedTime:Number;
		private var waitTime:Number;
		private var numComplete:uint;
		
		private static const IDLE_STATE:String		= "idle_state";
		private static const MOVE_STATE:String		= "move_state";
		private static const ANGRY_STATE:String		= "angry_state";
		
		public function WormMassSystem()
		{
			super(WormMassNode, updateNode);
			
			this.state = WormMassSystem.IDLE_STATE;
			this.elapsedTime = 0;
			this.waitTime = Utils.randInRange(2, 8);
			this.numComplete = 0;
		}
		
		private function updateNode(node:WormMassNode, time:Number):void
		{
			if(node.sleep.sleeping) return;
			
			switch(node.mass.wormBoss.state)
			{
				case WormBoss.IDLE_STATE:
					if(node.target.damage > 0)
					{
						node.mass.boss.add(new FollowTarget(this.group.shellApi.player.get(Spatial), 0.001));
						
						var motion:Motion = this.group.getEntityById("body").get(Motion);
						motion.rotationAcceleration = 50;
						motion.rotationMaxVelocity = 50;
						
						node.mass.wormBoss.state = MOVE_STATE;
					}
				break;
				
				case WormBoss.ANGRY_STATE:
				case WormBoss.MOVE_STATE:
					if(node.target.isHit)
					{
						node.target.isHit = false;
						node.timeline.gotoAndPlay("start");
						node.audio.play(SoundManager.EFFECTS_PATH + "boss_shell_crack_0" + Utils.randInRange(1, 2) + ".mp3", false, SoundModifier.EFFECTS);
						
						if(node.target.damage >= node.target.maxDamage && !node.target.isTriggered)
						{
							node.target.isTriggered = true;
							node.audio.play(SoundManager.EFFECTS_PATH + "boss_shell_break_0" + Utils.randInRange(1, 2) + ".mp3", false, SoundModifier.EFFECTS);
							
							node.mass.wormBoss.state = WormBoss.ANGRY_STATE;
							
							this.state = WormMassSystem.MOVE_STATE;
							this.elapsedTime = 0;
							this.waitTime = Utils.randInRange(2, 8);
							this.numComplete = 0;
							for(var mass2:WormMassNode = this.nodeList.head; mass2; mass2 = mass2.next)
								mass2.mass.state = WormMass.EXPAND_STATE;
							
							var massNumber:uint = uint(node.id.id.charAt(4));
							for(var i:uint = 0; i < 2; i++)
							{
								var tentacle:Entity = new Entity();
								this.group.addEntity(tentacle);
								
								var sprite:Sprite = new Sprite();
								sprite.mouseChildren = false;
								sprite.mouseEnabled = false;
								var container:DisplayObjectContainer = node.mass.boss.get(Display).displayObject["tentacleContainer"];
								tentacle.add(new Display(sprite, container));
								
								var spatial:Spatial = new Spatial(0, 0);
								switch(massNumber)
								{
									case 1: spatial.rotation = -157.5; break;
									case 2: spatial.rotation = -67.5;  break;
									case 3: spatial.rotation = 22.5;   break;
									case 4: spatial.rotation = 112.5;  break;
								}
								spatial.rotation += (i * 45);
								tentacle.add(spatial);
								
								//Fancy. Ass. Mathematics!
								tentacle.add(new Id("tentacle" + (massNumber + ((massNumber - 1) + i))  ));
								
								var tent:Tentacle = new Tentacle(17);
								tent.target = this.group.shellApi.player.get(Spatial);
								tent.reference = node.mass.boss.get(Spatial);
								tentacle.add(tent);
								
								tentacle.add(new Sleep(false, true));
								tentacle.add(new WormTentacle(node.mass.boss.get(WormBoss)));
								tentacle.add(new MovieClipHit(EnemyType.ENEMY_HIT, "ship"));
								
								var audio:Audio = new Audio();
								tentacle.add(audio);
								audio.play(SoundManager.EFFECTS_PATH + "tendrils_idle_01_L.mp3", true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
								tentacle.add(new AudioRange(3000));
								
								var target:DamageTarget = new DamageTarget();
								target.maxDamage = 10; //0.5 or 10
								target.damageFactor = new Dictionary();
								target.damageFactor[WeaponType.GUN] = 1;
								target.damageFactor[WeaponType.SCALPEL] = 1;
								target.hitParticleColor1 = Tentacle.BORDER_COLOR;
								target.hitParticleColor2 = Tentacle.BASE_COLOR;
								tentacle.add(target);
								
								var hazard:Hazard = new Hazard();
								hazard.damage = 0.05;
								hazard.coolDown = 1;
								tentacle.add(hazard);
								
								EntityUtils.addParentChild(tentacle, node.mass.boss);
							}
							
							node.mass.wormBoss.numMasses--;
							
							var tween:Tween = new Tween();
							node.entity.add(tween);
							var object:Object = { alpha:0, onComplete:this.group.removeEntity, onCompleteParams:[node.entity] };
							tween.to(node.entity.get(Display), 1, object);
						}
					}
					
					switch(this.state)
					{
						case WormMassSystem.IDLE_STATE:
							if(updateState(time, WormMassSystem.MOVE_STATE))
							{
								for(var mass:WormMassNode = this.nodeList.head; mass; mass = mass.next)
									mass.mass.state = WormMass.EXPAND_STATE;
							}
						break;
						
						case WormMassSystem.MOVE_STATE:
							switch(node.mass.wormBoss.state)
							{
								case WormBoss.ANGRY_STATE:	updateMoveState(node, time, 80, 50);	break;
								case WormBoss.MOVE_STATE:	updateMoveState(node, time, 20, 25);	break;
							}
						break;
					}
				break;
			}
		}
		
		private function updateState(time:Number, nextState:String):Boolean
		{
			this.elapsedTime += time;
			if(this.elapsedTime >= waitTime)
			{
				this.elapsedTime = 0;
				this.waitTime = Utils.randInRange(2, 8);
				this.state = nextState;
				return true;
			}
			return false;
		}
		
		private function updateMoveState(node:WormMassNode, time:Number, speed:Number, distance:uint):void
		{
			switch(node.mass.state)
			{
				case WormMass.IDLE_STATE: return;
				
				case WormMass.EXPAND_STATE:
					node.spatial.x += speed * time;
					node.spatial.y += speed * time;
					
					if(node.spatial.x > distance && node.spatial.y > distance)
						node.mass.state = WormMass.CONTRACT_STATE;
				break;
				
				case WormMass.CONTRACT_STATE:
					node.spatial.x -= speed * time;
					node.spatial.y -= speed * time;
					
					if(node.spatial.x < 0 && node.spatial.y < 0)
					{
						node.spatial.x = 0;
						node.spatial.y = 0;
						
						node.mass.state = WormMass.IDLE_STATE;
						
						this.numComplete++;
						if(this.numComplete >= node.mass.wormBoss.numMasses)
						{
							this.state = WormMassSystem.IDLE_STATE;
							this.numComplete = 0;
						}
					}
				break;
			}
		}
	}
}