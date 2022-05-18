package game.scenes.virusHunter.foreArm.systems
{	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.EntityType;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.hit.Mover;
	import game.components.hit.Radial;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.foreArm.components.BossSpawn;
	import game.scenes.virusHunter.foreArm.components.Cut;
	import game.scenes.virusHunter.foreArm.components.ForeArmState;
	import game.scenes.virusHunter.foreArm.nodes.CutNode;
	import game.scenes.virusHunter.foreArm.nodes.ForeArmStateNode;
	import game.scenes.virusHunter.shared.ShipGroup;
	import game.scenes.virusHunter.shared.ShipScene;
	import game.scenes.virusHunter.shared.components.DamageTarget;
	import game.scenes.virusHunter.shared.components.EnemySpawn;
	import game.scenes.virusHunter.shared.components.JoesHealth;
	import game.scenes.virusHunter.shared.components.KillCount;
	import game.scenes.virusHunter.shared.data.EnemyType;
	import game.scenes.virusHunter.shared.nodes.JoesHealthNode;
	import game.scenes.virusHunter.shared.nodes.KillCountNode;
	import game.scenes.virusHunter.shared.nodes.SceneWeaponTargetNode;
	import game.systems.GameSystem;
	import game.util.ClassUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class ForeArmTargetSystem extends GameSystem
	{
		public function ForeArmTargetSystem( scene:ShipScene, shipGroup:ShipGroup )
		{
			super( SceneWeaponTargetNode, updateNode );
			_scene = scene;
			_shipGroup = shipGroup;
			_triggerVictoryPopup = new Signal();
			_triggerShockSpawn = new Signal();
		}
		
		private function updateNode( node:SceneWeaponTargetNode, time:Number ):void
		{
			var cutNode:CutNode;
			var tween:Tween;
			var hitId:String;
			var art:Entity;
			var entity:Entity;
			var state:String;
			var timeline:Timeline;
			var damageTarget:DamageTarget; 
			
			var joesHealthNode:JoesHealthNode = _joesHealthNode.head;
			var foreArmStateNode:ForeArmStateNode = _foreArmStateNodes.head as ForeArmStateNode;
			var foreArmState:ForeArmState = foreArmStateNode.foreArmState;
			var killCount:KillCount = _killCountNodes.head.killCount;
			
			if( joesHealthNode )
			{
				var joesHealth:JoesHealth = joesHealthNode.joesHealth;
				var barDisplay:MovieClip = MovieClip( joesHealthNode.display.displayObject ).bar;
	
				joesHealth.timer ++;
				
				if( joesHealth.timer >= joesHealth.timerWait )
				{
					joesHealth.damageTick = true;
					joesHealth.timer = 0;
				}
				
	 			for( cutNode = _cutNodes.head; cutNode; cutNode = cutNode.next )
				{
					if( cutNode.cut.state == cutNode.cut.SEALED && cutNode.cut.health < cutNode.cut.maxHealth )
					{
						hitId = removeTarget( cutNode.id.id );
						var dmg:Number = Math.ceil( cutNode.cut.health );
						art = _scene.getEntityById( hitId + "Art" );
						
						switch( dmg )
						{
							case 3:
								state = "firstDamage";
								break;
							case 2:
								state = "secondDamage";
								break;
							case 1:
								state = "thirdDamage";
								break;
							case 0:
								state = "fullyOpen";
								break;
						}
						timeline = art.get( Timeline );
						timeline.gotoAndStop( state );
						
						if( cutNode.cut.health < 0 )
						{
							entity = _scene.getEntityById( hitId );
							
							cutNode.cut.health = 0;
							cutNode.damageTarget.damage = 0;
							_cutsHealed --;
							cutNode.cut.state = cutNode.cut.OPEN;
							cutNode.damageTarget.isTriggered = false;
							_shipGroup.addSpawn( cutNode.entity, EnemyType.RED_BLOOD_CELL, 3, new Point(80, 40), new Point(-30, -40), new Point(40, 30), .5 );   // anywhere
							var mover:Mover = new Mover();
							mover.acceleration = new Point( -400, 150 );
							
							entity.add( mover );
						}
					}
					
					else if( joesHealth.damageTick && cutNode.cut.state == cutNode.cut.OPEN )
					{
						joesHealth.currentHealth -= BLOOD_LOSE_DAMAGE;
						joesHealth.percent = joesHealth.currentHealth / joesHealth.range;
						barDisplay.scaleX = joesHealth.percent;
					}
				}
				
				if( joesHealth.currentHealth <= 0 )
				{
					damageTarget = this.group.shellApi.player.get(DamageTarget);
					damageTarget.damage = damageTarget.maxDamage;
				}
				joesHealth.damageTick = false;
				
				if( foreArmState.state == foreArmState.SPAWNS_KILLED && _cutsHealed == 3 )
				{
					_scene.removeEntity( joesHealthNode.entity );
					_triggerShockSpawn.dispatch();
					foreArmState.state = foreArmState.BATTLE_WON;
				}
			}
			
			if( node.collider.isHit && !node.damageTarget.isTriggered )
			{
				hitId = removeTarget( node.id.id );
				entity = _scene.getEntityById( hitId );
				art = _scene.getEntityById( hitId + "Art" );
				var target:Entity = _scene.getEntityById( hitId + "Target" );
				
				var bossSpawn:BossSpawn;
				var sound:String;
				var audio:Audio;
				
				if( hitId.indexOf( BOSS_SPAWN ) > -1 )
				{
					if( node.collider.collider.get( EntityType ).type == "scalpel" || node.collider.collider.get( EntityType ).type == "basicGun" )
					{
						bossSpawn = art.get( BossSpawn );
					
						if( bossSpawn )
						{
							if( bossSpawn.bossState != bossSpawn.DEAD && bossSpawn.bossState != bossSpawn.WOUNDED && bossSpawn.bossState != bossSpawn.SPAWN && bossSpawn.bossState != bossSpawn.HIT )
							{
								if( node.damageTarget.damage >= node.damageTarget.maxDamage )
								{
									bossSpawn.bossState = bossSpawn.WOUNDED;
									timeline = art.get( Timeline );
									
									timeline.gotoAndPlay( "defeat" );
									sound = BOSS_DEAD;
									
									audio = entity.get(Audio);
									
									if( audio == null )
									{
										audio = new Audio();
										
										entity.add(audio);
									}
									
									audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
					
									SceneUtil.addTimedEvent( _shipGroup, new TimedEvent( 2, 1, Command.create( _scene.removeEntity, entity )));
								}
								else
								{
									bossSpawn.bossState = bossSpawn.HIT;
									timeline = art.get( Timeline );
			     					timeline.gotoAndPlay( "hit" );
									sound = BOSS_HIT;
									audio = entity.get(Audio);
									
									if( audio == null )
									{
										audio = new Audio();
										
										entity.add(audio);
									}
									
									audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
								}
							}
						}
					}
				}
				
				else if( hitId.indexOf( BLOOD_FLOW ) > -1 && node.collider.collider.get( EntityType ).type == "goo" )
				{
					if( node.damageTarget.damage >= node.damageTarget.maxDamage )
					{
						art = _scene.getEntityById( hitId + "Art" );
						var id:String = hitId.slice( 9, 10 );
						timeline = art.get( Timeline );
						timeline.gotoAndPlay("startFill");
						entity.remove(Mover);
						node.damageTarget.isTriggered = true;
						
						var cut:Cut = target.get( Cut );
						cut.state = cut.SEALED;
						cut.health = cut.maxHealth;
						_cutsHealed++;
						
						target.remove( EnemySpawn );
						audio = entity.get( Audio );
						sound = CUT_HEALED;
						
						if( audio == null )
						{
							audio = new Audio();
							
							entity.add(audio);
						}
						
						audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
					}
					
					else
					{
						sound = CUT_HIT;
						if( audio == null )
						{
							audio = new Audio();
							
							entity.add(audio);
						}
						
						audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
					}
				}
				
				if( hitId.indexOf( CALCIFICATION ) > -1&& node.collider.collider.get( EntityType ).type == "scalpel" )
				{	
					if( node.damageTarget.damage >= node.damageTarget.maxDamage )
					{
						entity.remove(Radial);
						node.damageTarget.isTriggered = true;
						tween = new Tween();
						node.entity.add(tween);
						
						removeEntity( node.entity );
						timeline = art.get( Timeline );
						timeline.gotoAndPlay( "break" );
						killCount.count[ "calcium" ] ++;
						if( killCount.count[ "calcium" ] == 6 )
						{
							_scene.shellApi.completeEvent( _events.CALCIFCATION_REMOVED );
							_scene.playMessage( "arm_resolved", false, "arm_resolved" );
						}
					}
					sound = CALC_HIT;
					audio = entity.get(Audio);
					
					if( audio == null )
					{
						audio = new Audio();
						
						entity.add(audio);
					}
					if( !audio.isPlaying( SoundManager.EFFECTS_PATH + sound ))
					{
						audio.play( SoundManager.EFFECTS_PATH + sound, false, SoundModifier.POSITION );
					}
				}
				if( foreArmState.state == foreArmState.BATTLE_WON )
				{	
					if( hitId.indexOf( NERVE ) > -1 && node.collider.collider.get( EntityType ).type == "shock" )
					{
						for( var number:int = 1; number < 3; number ++ )
						{
							entity = _scene.getEntityById( "muscle" + number + "Art" );
							timeline = entity.get( Timeline );
							timeline.paused = false;
							
							entity = _scene.getEntityById( "nerve" + number + "Target" );
							_scene.removeEntity( entity );
							
							_scene.shellApi.triggerEvent( _events.MUSCLE_CONTRACT );
						}
							
						node.damageTarget.isTriggered = true;
						var locked:Entity = _scene.getEntityById( "musclesLocked" );
						locked.remove( Radial );
						_triggerVictoryPopup.dispatch();
					}
				}
			}
		}
		
		/*********************************************************************************
		 * UTILS
		 */
		private function reloadScene():void
		{
			_scene.shellApi.setUserField("damage", 0, _scene.shellApi.island);
			_scene.shellApi.loadScene(ClassUtils.getClassByObject(_scene), _scene.shellApi.profileManager.active.lastX, _scene.shellApi.profileManager.active.lastY);
		}
		
		private function removeEntity(entity:Entity):void
		{
			_scene.removeEntity(entity);
		}
		
		override public function addToEngine(systemManager:Engine) : void
		{
			_cutNodes = systemManager.getNodeList( CutNode );
			_joesHealthNode = systemManager.getNodeList( JoesHealthNode );
			_foreArmStateNodes = systemManager.getNodeList( ForeArmStateNode );
			_killCountNodes = systemManager.getNodeList( KillCountNode );
			_events = group.shellApi.islandEvents as VirusHunterEvents;
			
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(SceneWeaponTargetNode);	
			systemManager.releaseNodeList( CutNode );
			systemManager.releaseNodeList( JoesHealthNode );
			systemManager.releaseNodeList( ForeArmStateNode );
			super.removeFromEngine(systemManager);
		}
		
		private function removeTarget(id:String):String
		{
			var index:Number = id.indexOf("Target");
			
			return(id.slice(0, index));
		}
		
		public var _triggerVictoryPopup:Signal;
		public var _triggerShockSpawn:Signal;
		
		static private const CALCIFICATION:String = "calc";
		static private const CALC_HIT:String = "stone_impact_01.mp3";
		static private const BOSS_SPAWN:String 	= "enemySpawn";
		static private const NERVE:String = "nerve";
		static private const BLOOD_FLOW:String = "bloodFlow";
		static private const BLOOD_LOSE_DAMAGE:uint = 5;
		static private const BOSS_HIT:String = "squish_09.mp3";
		static private const BOSS_DEAD:String = "squish_10.mp3";
		static private const CUT_HEALED:String = "squish_07.mp3";
		static private const CUT_HIT:String = "squish_08.mp3";
		
		private var _events:VirusHunterEvents;
		private var _scene:ShipScene;
		private var _shipGroup:ShipGroup;
		
		private var _cutNodes:NodeList;
		private var _joesHealthNode:NodeList;
		private var _foreArmStateNodes:NodeList;
		private var _killCountNodes:NodeList;
		
		private var _cutsHealed:int = 0;
	}
}

